# realsense-imu-streaming
Goal: Stream real-time video and IMU sensor data from a RealSense D435i camera connected to a Raspberry Pi 4 over WiFi to a remote device or application.

# RealSense D435i IMU Streaming

A simple Python implementation for streaming IMU data (accelerometer and gyroscope) from Intel RealSense D435i camera over WiFi using UDP protocol.

## Hardware Requirements

- Intel RealSense D435i camera
- Raspberry Pi 4 Model B (or any Linux/Windows machine)
- WiFi network connection

## Software Requirements

- Python 3.7+
- Intel RealSense SDK (librealsense2)
- Required Python packages (see requirements.txt)

## Installation

### 1. Install Intel RealSense SDK

**On Ubuntu/Raspberry Pi:**
```bash
# Add Intel server to the list of repositories
sudo mkdir -p /etc/apt/keyrings
curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/librealsense.list
sudo apt-get update

# Install the libraries
sudo apt-get install librealsense2-dkms
sudo apt-get install librealsense2-utils
sudo apt-get install librealsense2-dev
sudo apt-get install librealsense2-dbg
```

**On Windows:**
Download and install from [Intel RealSense SDK Releases](https://github.com/IntelRealSense/librealsense/releases)

### 2. Install Python Dependencies

```bash
pip install -r requirements.txt
```

## Project Structure

```
realsense-imu-streaming/
├── README.md
├── requirements.txt
├── server/
│   ├── __init__.py
│   ├── imu_server.py
│   └── realsense_interface.py
├── client/
│   ├── __init__.py
│   ├── imu_client.py
│   └── visualizer.py
├── config/
│   └── config.py
├── examples/
│   ├── basic_streaming.py
│   └── data_logging.py
└── tests/
    ├── test_server.py
    └── test_client.py
```

## Quick Start

### 1. Start the IMU Server (on Raspberry Pi)

```bash
cd server
python imu_server.py --host 0.0.0.0 --port 8888
```

### 2. Start the IMU Client (on remote device)

```bash
cd client
python imu_client.py --server-ip <RASPBERRY_PI_IP> --port 8888
```

### 3. View Real-time IMU Data

```bash
cd client
python visualizer.py --server-ip <RASPBERRY_PI_IP> --port 8888
```

## Configuration

Edit `config/config.py` to customize:
- IMU sampling rates (default: 200Hz)
- Network settings
- Data format options
- Logging preferences

## API Reference

### Server API

```python
from server.imu_server import IMUServer

server = IMUServer(host='0.0.0.0', port=8888)
server.start()
```

### Client API

```python
from client.imu_client import IMUClient

client = IMUClient(server_ip='192.168.1.100', port=8888)
client.connect()
data = client.get_imu_data()
```

## Data Format

IMU data is transmitted as JSON over UDP:

```json
{
  "timestamp": 1234567890.123,
  "accelerometer": {
    "x": 0.123,
    "y": -0.456,
    "z": 9.789
  },
  "gyroscope": {
    "x": 0.001,
    "y": -0.002,
    "z": 0.003
  },
  "frame_number": 12345
}
```

## Performance

- **Bandwidth**: ~50 KB/s at 200Hz sampling rate
- **Latency**: <10ms over local WiFi
- **Reliability**: UDP with optional packet loss detection

## Troubleshooting

### Common Issues

1. **Camera not detected**: Check USB connection and permissions
2. **Network connection failed**: Verify IP address and firewall settings
3. **High latency**: Check WiFi signal strength and network congestion

### Debug Mode

Enable debug output:
```bash
python imu_server.py --debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Roadmap

- [ ] Add video streaming capability
- [ ] Implement data compression
- [ ] Add TCP fallback option
- [ ] Create mobile client app
- [ ] Add data recording/playback
- [ ] Implement sync with external devices

## Support

For issues and questions, please open a GitHub issue or check the [Intel RealSense documentation](https://dev.intelrealsense.com/).
