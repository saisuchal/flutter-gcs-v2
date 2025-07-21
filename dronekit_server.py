import socket
import threading
import time
import json

from dronekit import connect, VehicleMode, Command
from pymavlink import mavutil

lock = threading.Lock()

# === Connect to SITL ===
while True:
    try:
        print("🔌 Connecting to SITL on 127.0.0.1:5763...")
        vehicle = connect('tcp:127.0.0.1:5763', wait_ready=True, timeout=60)
        print("✅ Connected to SITL.")
        break
    except Exception as e:
        print(f"❌ Connection failed: {e}. Retrying in 5s...")
        time.sleep(5)

# === Drone Control Functions ===

def set_mode(mode_name):
    print(f"➡️ Setting mode to {mode_name}")
    vehicle.mode = VehicleMode(mode_name)
    while vehicle.mode.name != mode_name:
        print(f"⏳ Waiting for mode change...")
        time.sleep(0.5)
    print(f"✅ Mode set to {mode_name}")

def arm_vehicle():
    print("🟢 Attempting to arm vehicle...")
    print(f"    is_armable: {vehicle.is_armable}")
    print(f"    mode: {vehicle.mode.name}")
    print(f"    EKF OK: {vehicle.ekf_ok}")
    print(f"    System Status: {vehicle.system_status.state}")

    vehicle.armed = True
    for i in range(20):
        if vehicle.armed:
            print("✅ Vehicle armed.")
            return
        print(f"⏳ Waiting for arming... ({i * 0.5}s)")
        time.sleep(0.5)

    print("❌ Arming failed. Check pre-arm conditions or mode.")

def disarm_vehicle():
    print("🔴 Disarming vehicle...")
    vehicle.armed = False
    while vehicle.armed:
        print("⏳ Waiting for disarming...")
        time.sleep(1)
    print("✅ Vehicle disarmed.")

def upload_mission(mission_items):
    print("📋 Uploading mission...")
    cmds = vehicle.commands
    cmds.clear()

    for item in mission_items:
        lat = item['lat']
        lon = item['lon']
        alt = item['alt']
        wp_type = item.get('type', 'WAYPOINT').upper()

        if wp_type == 'TAKEOFF':
            cmd = Command(
                0, 0, 0,
                mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
                mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
                0, 0, 0, 0, 0, 0,
                lat, lon, alt
            )
        elif wp_type == 'LAND':
            cmd = Command(
                0, 0, 0,
                mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
                mavutil.mavlink.MAV_CMD_NAV_LAND,
                0, 0, 0, 0, 0, 0,
                lat, lon, alt
            )
        else:  # Default: WAYPOINT
            cmd = Command(
                0, 0, 0,
                mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
                mavutil.mavlink.MAV_CMD_NAV_WAYPOINT,
                0, 0, 0, 0, 0, 0,
                lat, lon, alt
            )

        cmds.add(cmd)

    cmds.upload()
    print(vehicle.commands)
    print("✅ Mission uploaded.")

def start_uploaded_mission():
    print("🚀 Starting uploaded mission...")

    # 1. Set to GUIDED
    set_mode("GUIDED")

    # 2. Arm
    arm_vehicle()

    # 3. Takeoff to 10m
    if vehicle.mode.name == "GUIDED" and vehicle.armed:
        print("🛫 Taking off to 10m...")
        vehicle.simple_takeoff(10.0)
        while True:
            alt = vehicle.location.global_relative_frame.alt
            print(f"📡 Altitude: {alt:.1f}m")
            if alt >= 9.5:
                print("✅ Reached target altitude.")
                break
            time.sleep(1)

    # 4. Switch to AUTO
    print("🔁 Switching to AUTO for mission...")
    set_mode("AUTO")
    print("✅ Mission started.")


def arm_with_mode():
    set_mode("GUIDED")
    arm_vehicle()

def takeoff_now(altitude=10.0):
    print(f"🚁 Initiating takeoff to {altitude}m...")

    set_mode("GUIDED")
    arm_vehicle()

    print("🛫 Sending takeoff command...")
    vehicle.simple_takeoff(altitude)

    while True:
        current_alt = vehicle.location.global_relative_frame.alt
        print(f"📡 Altitude: {current_alt:.1f}m")
        if current_alt >= altitude * 0.95:
            print("✅ Target altitude reached.")
            break
        time.sleep(1)


# === TCP Handler ===

COMMANDS = {
    "LAND": lambda: set_mode("LAND"),
    "RTL": lambda: set_mode("RTL"),
    "STABILIZE": lambda: set_mode("STABILIZE"),
    "AUTO": lambda: set_mode("AUTO"),
    "START_MISSION": start_uploaded_mission,
    "ARM": arm_with_mode,
    "DISARM": disarm_vehicle,
    "TAKEOFF": lambda: takeoff_now(10.0),
}

def handle_client(client_socket):
    with client_socket:
        while True:
            try:
                data = client_socket.recv(4096).decode().strip()
                if not data:
                    break
                print(f"📥 Received: {data}")

                with lock:
                    if data in COMMANDS:
                        COMMANDS[data]()
                        client_socket.sendall(b"OK\n")
                    elif data.startswith("WAYPOINTS:"):
                        try:
                            mission_data = json.loads(data[len("WAYPOINTS:"):])
                            upload_mission(mission_data)
                            client_socket.sendall(b"OK: Mission uploaded\n")
                        except Exception as e:
                            print(f"❌ Mission parse error: {e}")
                            client_socket.sendall(f"ERROR: {e}\n".encode())
                    else:
                        client_socket.sendall(b"ERROR: Unknown command\n")
            except Exception as e:
                print(f"❌ Exception: {e}")
                client_socket.sendall(f"ERROR: {e}\n".encode())
                break

# === Server Entry Point ===

def start_server(host="0.0.0.0", port=6000):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(1)
    print(f"✅ DroneKit TCP server listening on {host}:{port}")

    while True:
        client_sock, addr = server.accept()
        print(f"🔌 Connection from {addr}")
        threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()

if __name__ == "__main__":
    start_server()
