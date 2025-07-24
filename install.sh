#!/bin/bash

# RealSense D435i Web Streamer Installation Script
# Run with: bash install.sh

set -e  # Exit on any error

echo "Starting RealSense D435i Web Streamer Installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This script is optimized for Raspberry Pi. Continuing anyway..."
fi

# Step 1: Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y \
    python3-pip python3-venv python3-dev \
    git cmake build-essential pkg-config \
    curl wget \
    libopencv-dev python3-opencv \
    libavcodec-dev libavformat-dev libswscale-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgtk-3-dev libcanberra-gtk3-dev \
    libssl-dev libusb-1.0-0-dev libudev-dev \
    libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev \
    libxinerama-dev libxcursor-dev libxi-dev

print_success "System dependencies installed"

# Step 3: Install RealSense SDK
print_status "Installing Intel RealSense SDK..."

# Add Intel's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -sSf https://librealsense.intel.com/Debian/apt-repo/conf/librealsense.public.key | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null

# Add repository
echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/librealsense.list

# Update and install
sudo apt update
sudo apt install -y librealsense2-dkms librealsense2-utils librealsense2-dev librealsense2-dbg

print_success "RealSense SDK installed"

# Step 4: Set up USB permissions
print_status "Setting up USB permissions..."

sudo tee /etc/udev/rules.d/99-realsense-libusb.rules > /dev/null <<'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b07", GROUP="plugdev", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", GROUP="plugdev", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5c", GROUP="plugdev", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b64", GROUP="plugdev", MODE="0666"
EOF

# Add user to plugdev group
sudo usermod -a -G plugdev $USER

# Reload udev rules
sudo udevadm control --reload-rules && sudo udevadm trigger

print_success "USB permissions configured"

# Step 5: Create project directory
print_status "Creating project directory..."
PROJECT_DIR="$HOME/realsense_streamer"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Step 6: Create Python virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Step 7: Install Python packages
print_status "Installing Python packages..."

# Upgrade pip first
pip install --upgrade pip

# Create requirements file
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
websockets==12.0
opencv-python==4.8.1.78
numpy==1.24.3
pyrealsense2==2.54.1
python-multipart==0.0.6
EOF

# Install packages
pip install -r requirements.txt

print_success "Python packages installed"

# Step 8: Create project files
print_status "Creating project files..."

# Create main.py (you'll need to copy the content manually)
cat > main.py << 'EOF'
# PLACEHOLDER - Copy the main.py content from the first artifact
# This is just a placeholder to create the file
print("Please copy the main.py content from the first artifact")
EOF

# Create web_interface.html (you'll need to copy the content manually)
cat > web_interface.html << 'EOF'
<!-- PLACEHOLDER - Copy the web_interface.html content from the second artifact -->
<!-- This is just a placeholder to create the file -->
<html><body><h1>Please copy the web_interface.html content from the second artifact</h1></body></html>
EOF

# Create startup script
cat > start_server.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python main.py
EOF

chmod +x start_server.sh

print_success "Project files created"

# Step 9: Test installation
print_status "Testing installation..."

# Test RealSense
if command -v rs-enumerate-devices &> /dev/null; then
    print_success "RealSense tools installed correctly"
else
    print_error "RealSense tools not found"
fi

# Test Python imports
source venv/bin/activate
if python3 -c "import pyrealsense2 as rs; print('RealSense Python OK')" 2>/dev/null; then
    print_success "RealSense Python binding works"
else
    print_error "RealSense Python binding failed"
fi

if python3 -c "import cv2, numpy, fastapi; print('Dependencies OK')" 2>/dev/null; then
    print_success "All Python dependencies work"
else
    print_error "Some Python dependencies failed"
fi


# Final instructions
echo ""
echo "Installation completed!"
echo ""
echo "Next steps:"
echo "1. Copy the main.py content from the first artifact to: $PROJECT_DIR/main.py"
echo "2. Copy the web_interface.html content from the second artifact to: $PROJECT_DIR/web_interface.html"
echo "3. Connect your RealSense D435i camera"
echo "4. Logout and login again (for USB permissions)"
echo "5. Test camera: rs-enumerate-devices"
echo "6. Start server: cd $PROJECT_DIR && ./start_server.sh"
echo ""
echo "The web interface will be available at: http://$(hostname -I | awk '{print $1}'):8000"
echo ""
echo "Optional: Enable auto-start with: sudo systemctl enable realsense-streamer.service"
echo ""
print_warning "Remember to logout and login again for USB permissions to take effect!"
EOF
