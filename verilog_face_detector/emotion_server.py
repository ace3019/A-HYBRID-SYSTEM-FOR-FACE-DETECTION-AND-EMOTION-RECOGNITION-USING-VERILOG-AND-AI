import socket
import sys
import argparse
import time
import random
import numpy as np

# Try to import TensorFlow/Keras
try:
    from tensorflow import keras
    KERAS_AVAILABLE = True
except ImportError:
    KERAS_AVAILABLE = False
    print("WARNING: TensorFlow not available, using MOCK classifier")

class EmotionClassifier:
    """Mini-Xception Emotion Classifier"""
    
    def __init__(self, model_path=None):
        self.emotions = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']
        self.model = None
        self.use_mock = True
        
        if model_path and KERAS_AVAILABLE:
            try:
                print(f"Loading Mini-Xception model from {model_path}...")
                self.model = keras.models.load_model(model_path)
                self.use_mock = False
                print("✓ Real model loaded successfully")
            except Exception as e:
                print(f"WARNING: Could not load model: {e}")
                print("Falling back to MOCK classifier")
        else:
            print("Using MOCK classifier (random predictions)")
    
    def predict(self, roi_pixels=None):
        """
        Predict emotion from ROI pixels
        Returns: (emotion_name, confidence)
        """
        if self.use_mock:
            # Mock prediction - random emotion
            emotion = random.choice(self.emotions)
            confidence = 80.0 + random.random() * 19.9
            return emotion, confidence
        else:
            # Real prediction using Mini-Xception model
            # Model expects 48x48 grayscale image, normalized to [0, 1]
            # For now, since we're not actually receiving pixels, use random data
            # In real implementation, reshape and normalize roi_pixels
            img = np.random.rand(1, 48, 48, 1).astype(np.float32)
            
            predictions = self.model.predict(img, verbose=0)
            emotion_idx = np.argmax(predictions[0])
            confidence = float(predictions[0][emotion_idx]) * 100
            
            return self.emotions[emotion_idx], confidence

def main():
    parser = argparse.ArgumentParser(description='Emotion Classification Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=8888, help='Port to bind to')
    parser.add_argument('--model', help='Path to model file (optional, uses mock if not provided)')
    args = parser.parse_args()

    print(f"Starting Emotion Server on {args.host}:{args.port}...")
    
    # Initialize classifier
    classifier = EmotionClassifier(args.model)

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server_socket.bind((args.host, args.port))
        server_socket.listen(1)
        print("Listening for connections...")

        while True:
            client_socket, addr = server_socket.accept()
            print(f"Connection from {addr}")
            
            try:
                # Expect header: "ROI x y w h\n"
                header = ""
                while '\n' not in header:
                    chunk = client_socket.recv(1).decode('utf-8')
                    if not chunk: break
                    header += chunk
                
                print(f"Received header: {header.strip()}")
                
                if header.startswith("ROI"):
                    parts = header.strip().split()
                    if len(parts) >= 5:
                        x, y, w, h = map(int, parts[1:5])
                        print(f"Processing ROI: x={x}, y={y}, w={w}, h={h}")
                        
                        # Predict emotion using classifier
                        emotion, confidence = classifier.predict()
                        response = f"{emotion} (confidence: {confidence:.2f}%)"
                        
                        print(f"Sending result: {response}")
                        client_socket.sendall((response + "\n").encode('utf-8'))
                    else:
                        print("Invalid ROI format")
                else:
                    print("Unknown command")
                    
            except Exception as e:
                print(f"Error handling client: {e}")
            finally:
                client_socket.close()
                print("Connection closed")
                
    except KeyboardInterrupt:
        print("\nStopping server...")
    finally:
        server_socket.close()

if __name__ == "__main__":
    main()