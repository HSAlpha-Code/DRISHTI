import os
import time
import math
import random
import glob
import cv2
import numpy as np
import threading
import json
from datetime import datetime
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

class AIHeadcountEngine:
    def __init__(self):
        self.channel_layer = get_channel_layer()
        self.is_running = False
        self.thread = None
        self.yolo_model = None
        self.video_cap = None
        self.lock = threading.Lock()

    def get_yolo_model(self):
        """
        Lazy-loads the Ultralytics YOLOv11 model.
        """
        if self.yolo_model is None:
            with self.lock:
                if self.yolo_model is None:
                    try:
                        from ultralytics import YOLO
                        model_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'yolo11n.pt')
                        if not os.path.exists(model_path):
                            model_path = 'yolo11n.pt'
                        self.yolo_model = YOLO(model_path)
                        print(f"[AI Engine] Active YOLOv11 model initialized successfully.")
                    except Exception as e:
                        print(f"[AI Engine Warning] Failed to load YOLOv11 model: {e}")
                        self.yolo_model = False
        return self.yolo_model if self.yolo_model is not False else None

    def process_video_frame_yolo(self, center_code: str, expected_count: int):
        """
        Actively runs YOLOv11 model inference on a video frame from simulated_classroom_cctv.mp4.
        Returns (frame, detected_person_count).
        """
        with self.lock:
            if self.video_cap is None or not self.video_cap.isOpened():
                base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
                video_path = os.path.join(base_dir, 'resources', 'simulated_classroom_cctv.mp4')
                self.video_cap = cv2.VideoCapture(video_path)
                if not self.video_cap.isOpened():
                    print(f"[AI Engine Error] Could not open video source {video_path}")
                    frame = np.zeros((480, 854, 3), dtype=np.uint8)
                    cv2.rectangle(frame, (0, 0), (854, 480), (20, 25, 30), -1)
                    return frame, 0

            ret, frame = self.video_cap.read()
            if not ret:
                # Restart video
                self.video_cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                ret, frame = self.video_cap.read()
                if not ret:
                    frame = np.zeros((480, 854, 3), dtype=np.uint8)
                    return frame, 0

        # Resize for consistent web display
        frame = cv2.resize(frame, (854, 480))
        annotated_frame = frame.copy()
        detected_count = 0

        yolo = self.get_yolo_model()
        if yolo is not None:
            try:
                # Use parameters from test.py
                results = yolo.predict(
                    source=frame,
                    conf=0.15,
                    imgsz=960,
                    classes=[0],  # Filter to target class
                    verbose=False
                )
                
                for r in results:
                    detected_count = len(r.boxes)
                    annotated_frame = r.plot()
            except Exception as ex:
                print(f"[YOLOv11 Inference Error] {ex}")

        # Render headcount badge (from test.py)
        cv2.rectangle(annotated_frame, (20, 20), (350, 80), (0, 0, 0), -1)
        cv2.putText(
            annotated_frame, 
            f"Classroom Count: {detected_count}", 
            (30, 60), 
            cv2.FONT_HERSHEY_SIMPLEX, 
            1.0, 
            (0, 255, 0), 
            2, 
            cv2.LINE_AA
        )
        
        # Add a banner for center code
        cv2.rectangle(annotated_frame, (20, 90), (350, 130), (0, 0, 0), -1)
        cv2.putText(
            annotated_frame,
            f"Center: {center_code} | Expected: {expected_count}",
            (30, 115),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 255),
            2,
            cv2.LINE_AA
        )
        
        # Draw CCTV HUD Header Overlay to keep it looking somewhat like a CCTV feed
        w, h = 854, 480
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(annotated_frame, f"REC LIVE | CAM-01 [{center_code}] | {now_str}", (15, h - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.48, (0, 255, 200), 1)

        # Blinking REC status dot
        dot_color = (0, 0, 255) if (int(time.time()) % 2 == 0) else (0, 200, 0)
        cv2.circle(annotated_frame, (w - 25, h - 24), 6, dot_color, -1)

        return annotated_frame, detected_count

    def process_center_keyframe(self, center_id: int):
        from centers.models import InstituteCenter
        from attendance.models import HeadcountLog
        from inspections.models import AuditTask

        try:
            center = InstituteCenter.objects.get(id=center_id)
        except InstituteCenter.DoesNotExist:
            return None

        # Process a frame from the simulated video
        frame, detected_headcount = self.process_video_frame_yolo(center.code, center.expected_capacity)

        new_score, new_level = center.recalculate_risk_score(detected_headcount)

        media_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'media', 'snapshots')
        os.makedirs(media_dir, exist_ok=True)
        frame_filename = f"snapshot_{center.code}_{int(time.time())}.jpg"
        frame_path = os.path.join(media_dir, frame_filename)
        cv2.imwrite(frame_path, frame)
        relative_snapshot_url = f"/media/snapshots/{frame_filename}"

        discrepancy = abs(center.expected_capacity - detected_headcount)
        log = HeadcountLog.objects.create(
            center=center,
            detected_headcount=detected_headcount,
            expected_headcount=center.expected_capacity,
            discrepancy=discrepancy,
            risk_score_snapshot=new_score,
            frame_snapshot=relative_snapshot_url,
            alert_triggered=(new_score >= 65.0)
        )

        created_task = None
        if new_score >= 65.0:
            active_task = AuditTask.objects.filter(center=center, status__in=['DISPATCHED', 'IN_PROGRESS']).first()
            if not active_task:
                task_code = f"TASK-MOSJE-{random.randint(1000, 9999)}"
                created_task = AuditTask.objects.create(
                    task_id=task_code,
                    center=center,
                    assigned_inspector="Inspector Rajesh V. (Flying Squad)",
                    status='DISPATCHED',
                    trigger_reason=f"YOLOv11 CCTV Discrepancy Alert: {discrepancy} missing beneficiaries. Risk Score spiked to {new_score}%",
                )

        if self.channel_layer:
            event_data = {
                'type': 'dashboard_update',
                'event_type': 'HEADCOUNT_UPDATE',
                'data': {
                    'center_id': center.id,
                    'center_code': center.code,
                    'center_name': center.name,
                    'expected_capacity': center.expected_capacity,
                    'current_headcount': detected_headcount,
                    'discrepancy': discrepancy,
                    'risk_score': new_score,
                    'risk_level': new_level,
                    'snapshot_url': relative_snapshot_url,
                    'timestamp': datetime.now().isoformat(),
                    'unannounced_dispatch_triggered': created_task is not None,
                    'dispatch_task_id': created_task.task_id if created_task else None
                }
            }
            try:
                async_to_sync(self.channel_layer.group_send)('dashboard_updates', event_data)
            except Exception as ex:
                pass

        return log

    def start_sampling_loop(self):
        if self.is_running:
            return
            
        self.is_running = True
        def worker():
            from centers.models import InstituteCenter
            while self.is_running:
                try:
                    centers = list(InstituteCenter.objects.all())
                    for center in centers:
                        if center.code == 'MOSJE-DEL-001':
                            self.process_center_keyframe(center.id)
                            time.sleep(1.0)
                except Exception as e:
                    print(f"[AI Engine Error] {e}")
                time.sleep(5.0)

        self.thread = threading.Thread(target=worker, daemon=True)
        self.thread.start()

    def stop_sampling_loop(self):
        self.is_running = False
        with self.lock:
            if self.video_cap is not None:
                self.video_cap.release()
                self.video_cap = None

ai_engine_instance = AIHeadcountEngine()
