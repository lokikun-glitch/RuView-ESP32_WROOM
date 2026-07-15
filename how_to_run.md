# How to Run RuView (WiFi DensePose)

This guide will walk you through setting up and running the RuView platform, from flashing the ESP32 firmware to viewing the real-time 3D heuristic skeleton in the browser.

## Prerequisites

1. **Hardware:** An ESP32 device (like an ESP32-WROOM or ESP32-S3) connected via USB.
2. **Python Environment:** Python 3.10+ installed with necessary dependencies (`uvicorn`, `fastapi`, `numpy`, `scipy`, `websockets`, `pyserial`).
3. **ESP-IDF Environment:** (Optional, but recommended) Espressif IDF installed for compiling/flashing firmware.

---

## Step 1: Flashing the ESP32 Node

The ESP32 is responsible for capturing Channel State Information (CSI) and forwarding it to your PC over UDP.

1. Connect your ESP32 to your PC via USB.
2. Find the COM port for your ESP32 (e.g., `COM19` or `COM7`). You can use the provided PowerShell script:
   ```powershell
   cd firmware\esp32-csi-node
   .\find_ports.ps1
   ```
3. Flash the firmware onto the ESP32. You can use standard `esptool.py` or the ESP-IDF:
   ```bash
   idf.py -p COM19 flash
   ```
   *Note: If you have a custom flash script (like `flash_loop.ps1`), you can run that instead.*

---

## Step 2: Monitoring the Hardware (Optional)

To verify the ESP32 is successfully booting and extracting CSI data, you can open a serial monitor:
```bash
python -m serial.tools.miniterm COM19 115200
```
*(Exit the monitor with `Ctrl + ]`)*

---

## Step 3: Starting the Backend Sensing Server

The Python backend acts as the Edge Compute layer. It receives the UDP stream from the ESP32 (on port `5005`), processes the DSP metrics (motion energy, phase data), and translates them into a dynamic 33-keypoint heuristic skeleton.

1. Open a new terminal.
2. Navigate to the project root directory.
3. Start the API/Sensing server using Uvicorn (from the `archive/v1` directory):
   ```bash
   cd archive\v1
   python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000
   ```
   *Alternatively, if running the direct websocket server:*
   ```bash
   python src\sensing\ws_server.py
   ```
   
You should see logs indicating that the server is probing for ESP32 UDP packets on port `5005` and successfully binding.

---

## Step 4: Viewing the UI Dashboard

The frontend UI visualizes the data sent by the backend. It connects via WebSockets to render the 3D skeleton.

1. Host the `ui` folder using a simple HTTP server (from the project root):
   ```bash
   python -m http.server 8080 -d ui
   ```
2. Open your web browser and navigate to:
   ```
   http://localhost:8080/observatory.html
   ```
3. In the Observatory dashboard, click the **Settings** (gear icon) and ensure the data source is set to **Live WebSocket**.

## Troubleshooting

- **Skeleton not moving / stuck at 0 Persons?** 
  Make sure your ESP32 is actively detecting presence and broadcasting over UDP. The backend DSP heuristic engine requires motion energy to break out of the static standing pose.
- **Service Worker Cache Issues:**
  The frontend aggressively caches files. If you made UI updates that aren't showing up, do a **Hard Refresh** (`Ctrl + Shift + R`) or check `ui/sw.js` to bump the cache version.
- **Port Conflicts:** 
  Make sure no other programs are using UDP port `5005` or TCP port `8080/8000`.
