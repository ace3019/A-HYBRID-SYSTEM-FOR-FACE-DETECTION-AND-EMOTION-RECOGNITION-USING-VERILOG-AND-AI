import subprocess
import webbrowser
import time
import sys
import os

def main():

    
    current_dir = os.path.dirname(os.path.abspath(__file__))

    # Check for virtual environment
    # Prefer local venv if it exists
    venv_python = os.path.join(current_dir, 'venv', 'bin', 'python')
    if os.path.exists(venv_python):
        python_exec = venv_python
        print(f"[*] Using virtual environment: {python_exec}")
    else:
        python_exec = sys.executable
        print(f"[*] Using system python: {python_exec}")
    
    # Path to app.py
    app_path = os.path.join(current_dir, 'app.py')
    
    # Command to run app
    cmd = [python_exec, app_path]
    
    print(f"[*] Launching Flask App...")
    
    try:
        # Start the Flask app as a subprocess
        # We don't capture stdout/stderr here so the user can see the logs directly
        process = subprocess.Popen(cmd)
        
        # Wait for the server to initialize (give it a few seconds)
        # We could poll the port, but a simple sleep is often sufficient for a helper script
        print("[*] Waiting for server to initialize...")
        time.sleep(4) 
        
        # Open the browser
        url = "http://127.0.0.1:5000"
        print(f"[*] Opening browser at {url}")
        webbrowser.open(url)
        
        # Keep the script running to keep the subprocess alive
        print("\n[+] System is live!")
        print("[!] Press Ctrl+C to stop the server and exit.")
        process.wait()
        
    except KeyboardInterrupt:
        print("\n\n[*] Stopping server...")
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
        print("[*] Server stopped. Goodbye!")
    except Exception as e:
        print(f"\n[!] An error occurred: {e}")
        if 'process' in locals() and process:
            process.terminate()

if __name__ == "__main__":
    main()
