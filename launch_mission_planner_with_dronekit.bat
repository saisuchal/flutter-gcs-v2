@echo off
echo 🔄 Launching Mission Planner...
start "" "C:\Program Files (x86)\Mission Planner\MissionPlanner.exe"

REM Wait for SITL to bind to 5763
timeout /t 20 >nul

echo 🚀 Starting DroneKit server...

REM Run in same terminal so you can see output/errors
"C:\Users\bhara\AppData\Local\Programs\Python\Python39\python.exe" "C:\Users\bhara\Desktop\dronekit_server.py"

pause
