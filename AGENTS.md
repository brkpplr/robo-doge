# Robo-Doge Agent Guide

This document is the operating guide for agents working in this repository. It records the project layout, Raspberry Pi runtime, hardware facts, software protocol, calibration behavior, synchronization workflow, known failures, and the evidence required before changing or exercising the robot.

## Scope and Safety

Robo-Doge is a physical quadruped robot controlled by a Raspberry Pi and a desktop Windows client. Code changes can cause servo movement, unexpected leg motion, brownouts, mechanical damage, or injury.

Before any command that can energize or move a servo:

- Keep hands, tools, cables, and loose clothing clear of all legs and linkages.
- Support the robot on a stable raised platform when testing poses or gait movement.
- Keep a physical battery disconnect or equivalent emergency power interruption immediately reachable.
- Never infer servo-rail safety from SSH availability, Wi-Fi connectivity, or a healthy Raspberry Pi 5 V rail.
- Treat every client calibration preview, save, stop, relax, gait, head, buzzer, or LED operation as hardware-affecting unless proven otherwise.
- Do not bypass a hardware warning by changing an ADC channel, suppressing an exception, or skipping initialization without identifying the underlying electrical relationship.
- Do not enter passwords, private keys, host secrets, or board serial numbers into source files, commits, issue comments, or chat.

Read-only diagnostics and syntax checks are preferred. Physical movement requires the operator to be present and prepared to disconnect power.

## Repository and Path Rules

The Windows checkout is normally:

```text
C:\Users\bruno\code\robo-doge
```

The Raspberry Pi checkout is:

```text
/home/thareos/robo-doge
```

The repository contains a lowercase `code` tree in the current checkout. The Pi runtime is case-sensitive and must use these paths:

```text
code/server
code/client
```

Do not silently substitute `Code/server` or `Code/client` on Linux. Always verify the path with `pwd`, `git status`, and `ls` before running a command.

Important directories and files:

- `code/server/main.py`: headless or GUI server entry point.
- `code/server/Server.py`: TCP sockets, camera transmission, power telemetry, command dispatch, and server shutdown.
- `code/server/Control.py`: inverse kinematics, calibration offsets, gait generation, pose state, relaxation, and servo commands.
- `code/server/Servo.py`: PCA9685-backed servo mapping. Its legacy `__main__` routine can move every channel and must not be run casually.
- `code/server/PCA9685.py`: I2C PWM driver.
- `code/server/ADS7830.py`: ADC driver and voltage conversion.
- `code/server/IMU.py`: MPU6050 access and calibration.
- `code/server/Ultrasonic.py`: distance sensor access.
- `code/client/Main.py`: desktop PyQt client, connection workflow, movement controls, and calibration window.
- `code/client/Client.py`: desktop TCP/video sockets and command sending.
- `code/client/Command.py` and `code/server/Command.py`: command string constants. Keep both copies compatible.
- `code/client/IP.txt`: desktop client target address.
- `code/client/point.txt`: desktop-side saved calibration pose.
- `code/server/point.txt`: Pi-side saved calibration reference/offset source.
- `docs/raspberry-pi-setup-and-debugging.md`: detailed historical runbook and diagnostic evidence.

Do not modify root-level meta-repository files for a Robo-Doge-only task. Changes belong in this repository unless the user explicitly asks for a meta-repo change.

## Hardware Inventory

Known Pi:

- Raspberry Pi 4 Model B Rev 1.1.
- Hostname: `Xark`.
- Linux account: `thareos`.
- Debian GNU/Linux 13.6 (trixie), `aarch64`.
- Last confirmed address during the 2026-09-07 investigation: `10.0.0.96`.
- The address is DHCP-supplied and can change.
- Last recorded Pi temperature: `38.9 C` during baseline.
- Last recorded throttling state: `throttled=0x0`.

Connected devices and interfaces:

- PCA9685 servo controller: I2C bus `1`, address `0x40`.
- MPU6050 IMU: I2C address `0x68`.
- ADS7830 ADC: I2C address `0x48`.
- Buzzer: GPIO17.
- Camera: OV5647, detected by `rpicam-hello --list-cameras`.
- Control TCP port: `5001`.
- Camera TCP port: `8001`.

Battery and voltage facts:

- Two 3.7 V cells in series should be approximately 7.4 V nominal and 8.4 V fully charged.
- The current server reads ADC channel `0` through `ADS7830.power(0)`.
- The conversion is `raw / 255 * 5 * 2`.
- Channel 0 was stable around 5.22 V in the recorded scan and is likely the regulated 5 V rail, not a verified battery-sense input.
- Other channels produced variable values between roughly 6.90 V and 7.96 V but were not identified as the battery input.
- Do not change the software to channel 7 or another channel until the board schematic, trace, or multimeter measurement identifies that channel.
- SSH proves Pi/network availability. It does not prove servo-rail voltage, battery current capacity, PCA9685 ground integrity, or mechanical safety.

## Connection and Startup

From Windows PowerShell, use the documented key only on the Windows machine:

```powershell
Resolve-DnsName Xark
Test-NetConnection 10.0.0.96 -Port 22
ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" `
  -o BatchMode=yes `
  -o PreferredAuthentications=publickey `
  thareos@Xark
```

If `Xark` does not resolve, use the confirmed current address, not a guessed address:

```powershell
ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" `
  -o BatchMode=yes `
  -o PreferredAuthentications=publickey `
  thareos@<confirmed-ip>
```

If SSH fails, do not assume the application is broken. Check the Pi power state, Wi-Fi SSID, DHCP lease, client isolation, host key, username, and key path. A TCP connection to port 22 followed by key authentication failure is different from a network timeout.

After login, collect a read-only baseline:

```bash
date -u +%Y-%m-%dT%H:%M:%SZ
whoami
hostname
hostname -I
uname -a
cat /etc/os-release
systemctl --failed --no-pager
vcgencmd get_throttled 2>/dev/null || true
ls -l /dev/i2c-* /dev/spidev* /dev/gpiochip* 2>/dev/null || true
ls -l /dev/serial/by-id 2>/dev/null || true
```

Run software-only checks before hardware startup:

```bash
cd ~/robo-doge
python3 -m compileall -q code/server
python3 -m compileall -q code/client
cd code/server
../../.venv/bin/python -m py_compile *.py
../../.venv/bin/python -c 'import Server; print("Server module import ok")'
```

The normal headless runtime command is:

```bash
cd ~/robo-doge/code/server
../../.venv/bin/python main.py -n -t
```

This is not a dry run. Constructing the server initializes hardware-facing classes, including servo, IMU, ADC, buzzer, ultrasonic, and control components. Start it only after the physical setup is understood and the robot is safely supported.

Stop the headless server with one `Ctrl+C` and wait for cleanup. Repeated `Ctrl+C` presses can interrupt thread joins, Python shutdown, and Picamera2 cleanup, producing secondary tracebacks. A traceback during repeated interruption does not necessarily mean the initial server operation failed.

### Desktop client startup

Start the PyQt desktop client on the Windows machine after the Pi server is listening:

```powershell
Set-Location C:\Users\bruno\code\robo-doge\code\client
..\..\.venv\Scripts\python.exe Main.py
```

The client must be launched with `code\client` as the working directory because it loads `IP.txt`, `point.txt`, and images using relative paths. Before launching, verify that `IP.txt` contains the Pi's current confirmed address. The file currently contains `10.0.0.96`, but the address is DHCP-supplied and may change.

In the client window:

1. Confirm the IP address field and click `Connect`.
2. Confirm that the control connection succeeds before using movement, calibration, relax, buzzer, LED, or other hardware controls.
3. Treat `Open Video` as optional. Port `5001` carries control and telemetry; port `8001` carries video. Control can work when camera capture or video connection fails.
4. Close the client with its window close control so the client can stop worker threads and close both sockets.

This client command can initialize the GUI without moving the robot, but clicking controls after connection can energize or move hardware. Use the physical preflight above before connecting to a powered robot.

## Server Behavior

The server opens two sockets:

- Port `5001`: command and telemetry connection.
- Port `8001`: video connection.

The command path can work while the camera path fails. Do not treat camera errors as proof that servo control failed.

The server sends power telemetry to the client in the form:

```text
CMD_POWER#<value>
```

Power telemetry remains part of the protocol even though server-side voltage warning output is intentionally quiet. `battery_reminder()` is currently a no-op, and the server should not print the repeated low-voltage warning. Do not reintroduce that warning without an explicit request.

Known normal or nonfatal messages:

- `DistanceSensorNoEcho`: the ultrasonic sensor received no echo. It is separate from servo and camera control.
- Camera/libcamera discovery messages: camera initialization may succeed even if capture later fails.
- V4L2/Unicam `Failed to queue buffer`: camera capture failure; investigate camera ribbon seating, connector state, and competing camera processes.

Camera checks on the Pi:

```bash
rpicam-hello --list-cameras
rpicam-hello -t 3000
fuser -v /dev/video0
```

The client treats video as optional. A failed port 8001 connection must not prevent port 5001 command control or cause an unset video connection attribute failure.

## Calibration Protocol and Semantics

Calibration has two different concepts that must not be conflated:

1. `point`: the live Cartesian foot pose used by inverse kinematics.
2. `calibration_point`: the persisted mechanical reference used to calculate servo angle offsets.

At startup, `Control.calibration()` converts the saved reference and current points into angle offsets. `read_current_pose()` reads PWM servo angles and reconstructs the current Cartesian pose. The desktop calibration window requests the current pose with:

```text
CMD_CALIBRATION#current
```

The server returns either:

```text
CMD_CALIBRATION#current#<12 values>
```

or:

```text
CMD_CALIBRATION#unavailable
```

The calibration UI keeps its adjustment buttons disabled until a valid current pose arrives. This avoids applying a preset pose merely by opening the window.

### Live XYZ preview

Each XYZ adjustment button changes the selected leg's local values and sends the complete four-leg pose:

```text
CMD_CALIBRATION#preview#<12 values>
```

The server preview handler replaces `Control.point`, disables the relaxation state for this controlled preview, and calls `Control.run()`. `run()` performs inverse kinematics, applies restrictions, maps angles to PCA9685 channels, and writes servo positions.

Because the complete pose is sent, a one-axis change can write multiple servo channels. Preview is therefore a physical actuation command, not a text-only edit. The robot must be raised or otherwise safely supported before testing.

The first preview must not insert the old default stop or relax pose. This is why the condition loop recognizes the preview command specially and transitions directly from the current state.

### Save

Save sends:

```text
CMD_CALIBRATION#save#<12 values>
```

The server validates the command length, replaces `calibration_point`, recalculates offsets with `calibration()`, and persists the values to the Pi-side `point.txt`. Save is a persistence/calibration-reference operation; it is not the live preview operation.

The desktop client also writes its local `code/client/point.txt`. The client and server point files serve different runtime roles and should not be assumed interchangeable.

### Mechanical interpretation

Recorded reconstructed rear angles were asymmetric:

```text
channels 8, 9, 10: approximately 84, 120, 51 degrees
channels 11, 12, 13: approximately 102, 91, 18 degrees
```

Channel 13 reached the software minimum while matching rear channels did not. This suggested a rear horn/linkage alignment issue or saved calibration offset, not necessarily an I2C fault. Inspect mechanical alignment before using Save repeatedly.

Do not run the legacy `Servo.py` all-channel main routine. Do not use `CMD_MOVE_STOP`, relax, or walking commands as a substitute for calibration preview.

## Historical Investigation and Findings

The following facts were established during the 2026-09-07 setup work:

1. The Pi was initially unreachable because the laptop and Pi were on different Wi-Fi conditions. Later the Pi resolved as `Xark` at `10.0.0.96` and key-only SSH succeeded.
2. ARM I2C was initially absent. Enabling it and rebooting created `/dev/i2c-1`.
3. PCA9685 responded at `0x40` on bus 1; HDMI buses 20 and 21 did not represent the robot bus.
4. MPU6050 and ADS7830 responded at `0x68` and `0x48`.
5. An unpowered or poorly powered connection board caused intermittent IMU I2C errors. After the connection board was powered, 100 IMU calibration samples completed.
6. An old server process held GPIO17 and caused `GPIO busy` during buzzer initialization. It was terminated and GPIO17 became unclaimed.
7. A bounded server startup completed hardware initialization and TCP startup without issuing movement.
8. The desktop client later successfully moved the robot, proving the command path and at least one servo actuation. Exact gait and mechanical conditions were not recorded.
9. The OV5647 was detected, but capture later reported V4L2/Unicam buffer queue errors. Camera discovery and camera streaming are separate claims.
10. The ADC channel 0 result was stable near 5.22 V and is not verified as battery voltage.
11. The original calibration UI changed values without moving the legs. This was corrected by adding the preview protocol described above.
12. Server console logging was quieted for repeated voltage warnings, power response prints, the server address line, and `close_recv`. Client telemetry remains enabled.

Some older sections of `docs/raspberry-pi-setup-and-debugging.md` preserve the state at the time of each historical test. Do not rewrite historical observations merely to make them agree with later results. Add a dated correction or clarification when needed.

## Git and Pi Synchronization Workflow

The Robo-Doge repository remote is:

```text
https://github.com/brkpplr/robo-doge.git
```

The Windows working tree is the place where code changes are reviewed and committed. Do not commit Pi-generated files, logs, private data, or temporary evidence.

On Windows, inspect before committing:

```powershell
Set-Location C:\Users\bruno\code\robo-doge
git status --short
git diff --check
git diff --stat
git diff
```

Run focused validation before committing. For Python changes:

```powershell
.\.venv\Scripts\python.exe -m py_compile code\client\Main.py code\client\Client.py code\server\Control.py code\server\Server.py
```

Commit only after reviewing the diff:

```powershell
git add code\client\Main.py code\client\Client.py code\server\Control.py code\server\Server.py docs\raspberry-pi-setup-and-debugging.md AGENTS.md
git commit -m "Describe the focused change"
git push origin main
```

The workspace may also use the meta-repository helper from `C:\Users\bruno\code`:

```powershell
Set-Location C:\Users\bruno\code
.\ScriptLib.ps1 --push
```

Use the helper only after checking what it will push. Never push unrelated child-repository changes accidentally.

On the Pi, first preserve or inspect local changes:

```bash
cd ~/robo-doge
git status --short
git remote -v
git branch --show-current
```

If the Pi checkout is clean and the branch is intended to follow `main`:

```bash
git pull --ff-only origin main
```

If the Pi has local changes, stop before pulling. Save them as an intentional commit or patch, or ask the operator how to preserve them. Do not use `git reset --hard`, `git checkout --`, or destructive cleanup to force a pull.

After pulling, verify the revision and compile the runtime:

```bash
git log -1 --oneline
cd code/server
../../.venv/bin/python -m py_compile *.py
```

Restart the server only after the code revision is confirmed. A failed SSH attempt means synchronization has not happened; do not claim the Pi is updated until `git log -1` on the Pi confirms the expected commit.

## Validation Checklist

For a software-only change:

- Read the current target files and preserve user edits.
- Run focused syntax or unit checks.
- Run `git diff --check`.
- Confirm no secrets or generated files were added.
- Review the final diff and status.

For a read-only Pi diagnostic:

- Confirm the target hostname/address and identity.
- Record UTC time, repository revision, power assumptions, exact commands, exit codes, and raw results.
- Confirm I2C device nodes and expected addresses only after the board and bus are identified.
- Do not write to GPIO, PWM, serial, or unknown I2C devices.

For a server startup test:

- Confirm robot support and clear legs.
- Confirm the Pi-side revision and clean checkout.
- Confirm the emergency disconnect is accessible.
- Start with the documented headless command.
- Treat camera and ultrasonic failures independently from command-port status.
- Stop with one `Ctrl+C` and wait.

For calibration preview:

- Confirm `CMD_CALIBRATION#current` returns a valid pose.
- Confirm the robot is supported and the operator can disconnect battery power.
- Change one axis by one small increment.
- Observe the intended leg and check for binding, hard stops, asymmetry, or unexpected movement.
- Stop immediately if any channel reaches a software limit or a linkage binds.
- Save only after mechanical alignment and pose behavior are understood.

## Agent Reporting Requirements

Every agent session that changes this repository should report:

- Files changed and why.
- Whether changes were local, committed, pushed, or pulled.
- Exact validation commands and results.
- Whether the Pi was contacted.
- Whether any hardware-affecting command was issued.
- Remaining uncertainty, especially battery sensing, servo rail, camera capture, ultrasonic echo, GPIO ownership, and mechanical alignment.

Never state that the robot is safe merely because SSH works, I2C responds, or the client connects. Distinguish software reachability, command acceptance, electrical health, and mechanical safety.
