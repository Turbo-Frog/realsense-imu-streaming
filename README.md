# RealSense D435i Web Streaming Setup

## Requirements (requirements.txt)
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
websockets==12.0
opencv-python==4.8.1.78
numpy==1.24.3
pyrealsense2==2.54.1
python-multipart==0.0.6
```

## Installation Steps

### 1. System Dependencies (Raspberry Pi 4)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install system dependencies
sudo apt install -y python3-pip python3-venv git cmake build-essential

# Install OpenCV dependencies
sudo apt install -y libopencv-dev python3-opencv

# Install RealSense SDK dependencies
sudo apt install -y libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev
sudo apt install -y libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
```

### 2. RealSense SDK Installation
```bash
# Add Intel RealSense repository
sudo mkdir -p /etc/apt/keyrings
curl -sSf https://librealsense.intel.com/Debian/apt-repo/conf/librealsense.public.key | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/librealsense.list

sudo apt update

# Install RealSense SDK
sudo apt install -y librealsense2-dkms librealsense2-utils librealsense2-dev
```

### 3. Python Environment Setup
```bash
# Create project directory
mkdir ~/realsense_streamer
cd ~/realsense_streamer

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install --upgrade pip
pip install fastapi uvicorn[standard] websockets opencv-python numpy pyrealsense2 python-multipart
```

### 4. Project Files
Create the following files in your project directory:

1. **main.py** - The Python server (from first artifact)
2. **web_interface.html** - The web interface (from second artifact)

### 5. USB Permissions (Important!)
```bash
# Add USB rules for RealSense
sudo tee /etc/udev/rules.d/99-realsense-libusb.rules > /dev/null <<EOF
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b07", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5c", GROUP="plugdev"
EOF

# Add user to plugdev group
sudo usermod -a -G plugdev $USER

# Reload udev rules
sudo udevadm control --reload-rules && sudo udevadm trigger

# Reboot or logout/login for group changes to take effect
```

## Running the Server

### 1. Test RealSense Connection
```bash
# Test if camera is detected
rs-enumerate-devices

# Test camera streaming (optional)
realsense-viewer
```

### 2. Start the Web Server
```bash
cd ~/realsense_streamer
source venv/bin/activate
python main.py
```

### 3. Access the Web Interface
- The server will display the local IP address when starting
- Access via: `http://[PI_IP_ADDRESS]:8000`
- Example: `http://192.168.1.100:8000`

## Network Configuration

### Find Your Pi's IP Address
```bash
# Method 1: ip command
ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1

# Method 2: hostname command
hostname -I

# Method 3: ifconfig (if available)
ifconfig wlan0 | grep 'inet ' | awk '{print $2}'
```

### Port Configuration
- **Default Port**: 8000
- **WebSocket**: Same port, `/ws` endpoint
- **Status API**: Same port, `/status` endpoint

### Firewall Settings (if needed)
```bash
# Allow port 8000
sudo ufw allow 8000/tcp

# Or disable firewall temporarily for testing
sudo ufw disable
```

## Performance Optimization

### 1. Raspberry Pi 4 Settings
```bash
# Increase GPU memory split
echo 'gpu_mem=128' | sudo tee -a /boot/config.txt

# Enable hardware acceleration
echo 'dtoverlay=vc4-kms-v3d' | sudo tee -a /boot/config.txt

# Reboot after changes
sudo reboot
```

### 2. System Monitoring
```bash
# Monitor system resources
htop

# Monitor temperature
vcgencmd measure_temp

# Monitor network usage
iftop
```

### 3. Adjust Stream Quality
In `main.py`, modify these parameters for performance:
```python
# JPEG quality (50-95, lower = smaller files)
cv2.IMWRITE_JPEG_QUALITY, 80

# Frame queue size (smaller = lower latency)
self.ir_frame_queue = queue.Queue(maxsize=5)

# WebSocket delay (smaller = higher CPU usage)
await asyncio.sleep(0.033)  # ~30 FPS
```

## Troubleshooting

### Common Issues

1. **"No device connected" error**
   - Check USB connection
   - Verify USB permissions
   - Try different USB port
   - Check `lsusb` output

2. **High CPU usage**
   - Reduce JPEG quality
   - Increase WebSocket delay
   - Lower frame rate in RealSense config

3. **Network lag**
   - Check WiFi signal strength
   - Reduce video quality
   - Use wired connection if possible

4. **Permission denied errors**
   - Ensure user is in `plugdev` group
   - Check udev rules are applied
   - Try running with `sudo` (not recommended for production)

### Debug Commands
```bash
# Check RealSense devices
rs-enumerate-devices

# Test camera access
python3 -c "import pyrealsense2 as rs; print('RealSense OK')"

# Check network connectivity
curl http://localhost:8000/status

# Monitor logs
tail -f /var/log/syslog | grep realsense
```

## Auto-Start Service (Optional)

Create systemd service for automatic startup:

```bash
# Create service file
sudo tee /etc/systemd/system/realsense-streamer.service > /dev/null <<EOF
[Unit]
Description=RealSense D435i Web Streamer
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/realsense_streamer
Environment=PATH=/home/pi/realsense_streamer/venv/bin
ExecStart=/home/pi/realsense_streamer/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable realsense-streamer.service
sudo systemctl start realsense-streamer.service

# Check status
sudo systemctl status realsense-streamer.service
```

## Features of the Web Interface

- **Real-time IR video streaming** at 640×480@30fps
- **Live IMU data display** (accelerometer & gyroscope at 200Hz)
- **Interactive charts** with 200-point history
- **Connection status monitoring**
- **Performance metrics** (FPS, data rate)
- **Responsive design** (works on mobile devices)
- **Snapshot saving** capability
- **Auto-reconnection** on connection loss

## Advanced Customization

### Add Multiple Camera Support
Modify the `initialize_camera()` method to handle multiple devices:
```python
ctx = rs.context()
devices = ctx.query_devices()
for device in devices:
    print(f"Found device: {device.get_info(rs.camera_info.name)}")
```

### Add Recording Capability
Implement video recording by saving frames to video files:
```python
import cv2
fourcc = cv2.VideoWriter_fourcc(*'XVID')
out = cv2.VideoWriter('output.avi', fourcc, 30.0, (640, 480))
```

### Custom Stream Processing
Add filters, detection algorithms, or computer vision processing:
```python
# Example: Add edge detection
edges = cv2.Canny(ir_image, 50, 150)
```