import os
import subprocess

pid = os.fork()

# Pid equal to 0 represents the created child process.
if pid == 0:
    os.setsid()
    subprocess.Popen(["/usr/bin/python3", "/home/app/script3.py"])
