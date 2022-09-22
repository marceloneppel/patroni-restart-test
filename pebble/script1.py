import subprocess
import time


subprocess.Popen(["/usr/bin/python3", "/home/app/script2.py"], close_fds=True)

# Just a loop to keep the program running.
while True:
    time.sleep(30)
