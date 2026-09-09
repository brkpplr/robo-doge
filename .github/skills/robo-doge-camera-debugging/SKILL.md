---
name: robo-doge-camera-debugging
description: 'Debug the optional robo-doge OV5647 camera and TCP video service. Use for rpicam failures, V4L2 or Unicam queue errors, port 8001 failures, and client video connection problems.'
argument-hint: 'Describe camera detection, capture output, port 8001 state, and recent camera users.'
---

# Robo-Doge Camera Debugging

Treat camera streaming as independent from the servo control path. Read the robot runbook before changing camera configuration.

## Procedure

1. On the Pi, identify the camera and test capture separately:
   ```bash
   rpicam-hello --list-cameras
   rpicam-hello -t 3000
   fuser -v /dev/video0
   pgrep -af 'rpicam|libcamera|python|Server'
   ss -ltnp | grep ':8001'
   ```
2. Distinguish detection from capture. An OV5647 listed by `rpicam-hello --list-cameras` does not prove that frames can be queued.
3. If capture reports V4L2 or Unicam buffer queue errors, check ribbon orientation, connector seating, camera ownership, and power before changing Python code.
4. Test TCP control port 5001 independently. A working control connection with a failed 8001 video connection is an expected separable state.
5. On Windows, treat `WinError 10061` on 8001 as no listener or a refused connection, not automatically as a wrong IP.
6. Preserve the client behavior that initializes `Client.connection` before video setup and closes partial sockets safely.

## Boundaries

- Do not make camera failure block servo diagnosis or control startup unless the application contract explicitly requires it.
- Do not kill an unknown process until its command line and ownership are identified.
- Record camera model, exact command output, cable state, server revision, and whether port 5001 still works.