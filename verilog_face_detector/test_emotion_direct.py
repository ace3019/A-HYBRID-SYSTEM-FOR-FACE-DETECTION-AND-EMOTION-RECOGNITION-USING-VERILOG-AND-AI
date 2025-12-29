#!/usr/bin/env python3
"""
Direct test of emotion server
Sends dummy face ROI data to test emotion classification
"""

import socket
import struct
import sys

def send_roi_to_server(host, port, x, y, width, height, pixel_data):
    """
    Send ROI data to emotion server
    
    Protocol (text-based):
    - Send: "ROI x y w h\n"
    - Receive: "Emotion (confidence: XX.XX%)\n"
    """
    try:
        # Connect to server
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        sock.connect((host, port))
        print(f"Connected to emotion server at {host}:{port}")
        
        # Send text command
        command = f"ROI {x} {y} {width} {height}\n"
        sock.sendall(command.encode('utf-8'))
        print(f"Sent ROI: x={x}, y={y}, width={width}, height={height}")
        
        # Receive response
        response = ""
        while '\n' not in response:
            chunk = sock.recv(1).decode('utf-8')
            if not chunk:
                break
            response += chunk
        
        response = response.strip()
        print(f"✓ Received emotion prediction: {response}")
        
        # Parse response: "Emotion (confidence: XX.XX%)"
        if '(' in response and ')' in response:
            emotion = response.split('(')[0].strip()
            confidence_str = response.split('confidence: ')[1].split('%')[0]
            confidence = float(confidence_str)
            return emotion, confidence
        else:
            print(f"✗ Could not parse response")
            return None, None
            
    except ConnectionRefusedError:
        print("✗ Connection refused. Is the emotion server running?")
        print("  Start it with: make start-server")
        return None, None
    except socket.timeout:
        print("✗ Connection timeout")
        return None, None
    except Exception as e:
        print(f"✗ Error: {e}")
        return None, None
    finally:
        sock.close()

def create_test_image(pattern='face'):
    """Create test image data (48x48 grayscale)"""
    width, height = 48, 48
    
    if pattern == 'face':
        # Create a simple face-like pattern
        # Darker regions for eyes and mouth
        pixels = bytearray(width * height)
        for y in range(height):
            for x in range(width):
                idx = y * width + x
                # Background
                pixels[idx] = 180
                
                # Left eye (darker oval)
                if (12 <= y <= 20) and (10 <= x <= 18):
                    pixels[idx] = 50
                
                # Right eye (darker oval)
                if (12 <= y <= 20) and (30 <= x <= 38):
                    pixels[idx] = 50
                
                # Mouth (darker curved region for smile)
                if (32 <= y <= 38) and (12 <= x <= 36):
                    # Curved smile
                    mouth_y = 35 - abs(x - 24) // 6
                    if y >= mouth_y:
                        pixels[idx] = 60
        
        return bytes(pixels), width, height
    
    elif pattern == 'random':
        # Random noise
        import random
        pixels = bytes([random.randint(0, 255) for _ in range(width * height)])
        return pixels, width, height
    
    else:
        # Uniform gray
        pixels = bytes([128] * (width * height))
        return pixels, width, height

def main():
    print("=" * 60)
    print("Emotion Server Direct Test")
    print("=" * 60)
    
    # Server config
    host = '127.0.0.1'
    port = 8888
    
    # Test patterns
    patterns = ['face', 'random', 'uniform']
    
    for pattern in patterns:
        print(f"\nTest {pattern.upper()} pattern:")
        print("-" * 60)
        
        pixels, width, height = create_test_image(pattern)
        emotion, confidence = send_roi_to_server(host, port, 10, 10, width, height, pixels)
        
        if emotion:
            print(f"✓ Test passed: Got {emotion} with {confidence:.1%} confidence")
        else:
            print("✗ Test failed")
            sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✓ All tests passed!")
    print("=" * 60)

if __name__ == '__main__':
    main()
