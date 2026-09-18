import cv2
from ultralytics import YOLO

def process_classroom_cctv(video_source, model_weights="yolo11n.pt"):
    """
    Processes CCTV footage to yield a concrete headcount per frame.
    
    :param video_source: Path to MP4 file or RTSP stream URL (e.g. 'rtsp://admin:pass@ip:port')
    :param model_weights: Custom head-detection weights or standard YOLO weights.
    """
    # Load model (Use fine-tuned head detection weights for best classroom results)
    model = YOLO(model_weights)

    cap = cv2.VideoCapture(video_source)
    if not cap.isOpened():
        print(f"Error: Could not open video source {video_source}")
        return

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Run inference
        # - conf=0.15: Lower threshold helps pick up heads in dark/rear classroom corners
        # - imgsz=960 or 1280: Higher resolution keeps small heads visible far away
        results = model.predict(
            source=frame,
            conf=0.15,
            imgsz=960,
            classes=[0],  # Filter to target class
            verbose=False
        )

        for r in results:
            # Extract number of detected heads
            headcount = len(r.boxes)
            
            # Draw detections
            annotated_frame = r.plot()

            # Render headcount badge on frame
            cv2.rectangle(annotated_frame, (20, 20), (350, 80), (0, 0, 0), -1)
            cv2.putText(
                annotated_frame, 
                f"Classroom Count: {headcount}", 
                (30, 60), 
                cv2.FONT_HERSHEY_SIMPLEX, 
                1.0, 
                (0, 255, 0), 
                2, 
                cv2.LINE_AA
            )

            # Display feed
            cv2.imshow("CCTV Classroom Attendance System", annotated_frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    # For a local video file:
    VIDEO_PATH = "simulated_classroom_cctv.mp4"
    
    # For a live CCTV camera stream, replace VIDEO_PATH with the RTSP URL:
    # VIDEO_PATH = "rtsp://username:password@192.168.1.100:554/stream1"
    
    process_classroom_cctv(VIDEO_PATH, model_weights="yolo11m.pt")