import os
import time
import math
import random
import cv2
import numpy as np
import threading
import json
from datetime import datetime
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

class AIHeadcountEngine:
    def __init__(self):
        self.hog = None
        try:
            if hasattr(cv2, 'HOGDescriptor'):
                self.hog = cv2.HOGDescriptor()
                if hasattr(cv2, 'HOGDescriptor_getDefaultPeopleDetector'):
                    self.hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
            elif hasattr(cv2, 'objdetect') and hasattr(cv2.objdetect, 'HOGDescriptor'):
                self.hog = cv2.objdetect.HOGDescriptor()
        except Exception as e:
            print(f"[OpenCV Init Warning] {e}")

        self.channel_layer = get_channel_layer()
        self.is_running = False
        self.thread = None

    def generate_synthetic_cctv_frame(self, center_code: str, expected_count: int, simulated_count: int):
        """
        Generates a realistic 854x480 CCTV keyframe snapshot with timestamp overlay,
        CCTV camera watermark, detected person bounding boxes, and headcount HUD.
        """
        h, w = 480, 854
        frame = np.zeros((h, w, 3), dtype=np.uint8)
        
        # Draw floor & wall perspective grid lines
        cv2.rectangle(frame, (0, 0), (w, h), (20, 25, 30), -1)
        cv2.line(frame, (0, 360), (w, 360), (40, 50, 60), 2)
        for i in range(0, w, 80):
            cv2.line(frame, (i, 360), (int(i * 0.8 + 80), h), (30, 40, 45), 1)

        # Draw detected individuals
        random.seed(int(time.time() // 5) + hash(center_code))
        for k in range(simulated_count):
            grid_x = 80 + (k % 6) * 120 + random.randint(-15, 15)
            grid_y = 180 + (k // 6) * 80 + random.randint(-10, 10)
            
            box_w, box_h = 50, 110
            x1, y1 = max(10, grid_x), max(50, grid_y)
            x2, y2 = min(w - 10, x1 + box_w), min(h - 50, y1 + box_h)

            color = (0, 220, 120) if abs(expected_count - simulated_count) < 5 else (0, 140, 255)
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.rectangle(frame, (x1, y1 - 22), (x1 + 80, y1), color, -1)
            cv2.putText(frame, f"Person {k+1}", (x1 + 4, y1 - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 255), 1)

        # Draw CCTV HUD Overlay Header
        cv2.rectangle(frame, (0, 0), (w, 40), (10, 15, 20), -1)
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, f"REC LIVE | CAM-01 [{center_code}] | {now_str}", (15, 26), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 255, 200), 2)

        # Draw Headcount Analytics Banner Footer
        cv2.rectangle(frame, (0, h - 45), (w, h), (15, 20, 25), -1)
        status_text = f"YOLO11 AI COUNT: {simulated_count} / EXPECTED: {expected_count}"
        cv2.putText(frame, status_text, (20, h - 16), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)

        return frame

    def process_center_keyframe(self, center_id: int):
        from centers.models import InstituteCenter
        from attendance.models import HeadcountLog
        from inspections.models import AuditTask

        try:
            center = InstituteCenter.objects.get(id=center_id)
        except InstituteCenter.DoesNotExist:
            return None

        cycle = (int(time.time()) // 10) % 6
        if center.code == 'MOSJE-DEL-002':
            simulated_detected = 12 if cycle in [1, 2, 3] else 18
        elif center.code == 'MOSJE-MUM-003':
            simulated_detected = 48
        else:
            simulated_detected = max(5, center.expected_capacity - random.randint(0, 8))

        old_score = center.risk_score
        old_level = center.risk_level
        new_score, new_level = center.recalculate_risk_score(simulated_detected)

        frame = self.generate_synthetic_cctv_frame(center.code, center.expected_capacity, simulated_detected)
        
        media_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'media', 'snapshots')
        os.makedirs(media_dir, exist_ok=True)
        frame_filename = f"snapshot_{center.code}_{int(time.time())}.jpg"
        frame_path = os.path.join(media_dir, frame_filename)
        cv2.imwrite(frame_path, frame)
        relative_snapshot_url = f"/media/snapshots/{frame_filename}"

        discrepancy = abs(center.expected_capacity - simulated_detected)
        log = HeadcountLog.objects.create(
            center=center,
            detected_headcount=simulated_detected,
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
                    trigger_reason=f"CCTV Discrepancy Alert: {discrepancy} missing beneficiaries. Risk Score spiked to {new_score}%",
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
                    'current_headcount': simulated_detected,
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
                        self.process_center_keyframe(center.id)
                        time.sleep(1.0)
                except Exception as e:
                    print(f"[AI Engine Error] {e}")
                time.sleep(5.0)

        self.thread = threading.Thread(target=worker, daemon=True)
        self.thread.start()

    def stop_sampling_loop(self):
        self.is_running = False

ai_engine_instance = AIHeadcountEngine()
