# Robo-Doge Raspberry Pi Setup and Debugging

This runbook records the Raspberry Pi integration for this Freenove Robo-Doge
checkout. It separates software checks from physical robot tests. Do not start
the server with the robot supported by an unsafe platform, and keep hands clear
of the legs whenever a powered test is authorized.

## Current status

The Pi is reachable from the Windows development machine on 2026-09-07 at
`10.0.0.96`. ARM I2C was enabled manually and the Pi was rebooted. The
PCA9685 and sensors respond on bus `1`, and one bounded server startup passed.
No movement command has been issued. A later server retry was blocked by GPIO17
being busy while the buzzer was initialized.

The last known connection details come from the `hardware-debugger` repository:

- Hostname: `Xark`
- Last verified IPv4 address: `10.0.0.96`
- Linux account: `thareos`
- SSH key path on Windows: `$env:USERPROFILE\\.ssh\\id_ed25519_xark`
- Expected platform: Raspberry Pi 4 Model B, Debian GNU/Linux 13 (trixie), `aarch64`

The address may have changed because it is supplied by DHCP. Confirm the Pi's
current address on the private Wi-Fi network before changing any project files.

## Repository layout and runtime

The robot runtime is under lowercase `code` on Linux:

- `code/server/main.py` is the Pi-side entry point.
- `code/server/Server.py` initializes the servo, ADC, buzzer, control, and
  ultrasonic components, then binds the server to the `wlan0` address.
- TCP port `5001` carries control commands.
- TCP port `8001` carries the camera stream.
- `code/client/Main.py` is the desktop GUI client.
- `code/client/IP.txt` contains the Pi address read by the client. The current
   checked-in value is `10.0.0.96`.

The normal Pi-side command, after dependencies and hardware configuration have
been verified, is:

```bash
cd ~/robo-doge/code/server
python3 main.py -n -t
```

`-n` disables the server GUI and `-t` starts the TCP server. This is not a
hardware dry-run: constructing the server initializes hardware-facing classes.
Treat it as a controlled bench test, not as a first connectivity probe.

Low battery is reported but no longer closes the server. The measured power
value is still sent to the client. The `-b` option remains accepted for
backward-compatible startup commands:

```bash
../../.venv/bin/python main.py -n -t -b
```

The server prints a warning when the measured value is below `6.4 V`. This does
not prove that the battery or ADC wiring is healthy. Do not issue movement
commands until the battery voltage has been checked with a multimeter and the
ADC channel has been verified.

In headless mode, stop the server with `Ctrl+C` once. The shutdown path closes
the TCP sockets and waits briefly for the worker threads. The previous
`RuntimeError: super-class __init__() of type MyWindow was never called` was
caused by headless mode calling the Qt window cleanup method even though no Qt
window had been initialized. Repeated `Ctrl+C` presses can still interrupt
Python or camera-library cleanup; wait for the first shutdown to finish.

## Reconnect and collect evidence first

Run these commands from PowerShell. The key remains on the Windows machine and
must not be copied to the Pi repository or to an evidence bundle.

```powershell
ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" thareos@Xark
```

```powershell
Resolve-DnsName Xark
Test-NetConnection 10.0.0.96 -Port 22
ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" `
  -o BatchMode=yes `
  -o PreferredAuthentications=publickey `
  thareos@Xark
```

If name resolution fails, retry the SSH command with `thareos@<confirmed-ip>`.
Do not repeatedly guess addresses or credentials. If the Pi has been rebuilt,
verify its host key before removing an old `known_hosts` entry.

After login, perform only the read-only baseline from
`hardware-debugger/docs/raspberry-pi-remote-diagnostics.md`. At minimum record:

```bash
date -u +%Y-%m-%dT%H:%M:%SZ
whoami
hostname
hostname -I
uname -a
cat /etc/os-release
systemctl --failed --no-pager
ls -l /dev/i2c-* /dev/spidev* /dev/gpiochip* 2>/dev/null || true
ls -l /dev/serial/by-id 2>/dev/null || true
```

Interface enumeration is observation only. Do not enable buses, scan an
unknown device, write to serial, or drive GPIO/PWM until the board revision,
voltage levels, power state, and target are known.

## Safe software setup sequence

Once SSH access is restored:

1. Confirm the Pi identity, OS, free storage, temperature, throttling state,
   failed services, and connected devices.
2. Clone or update this repository in the Pi user's home directory. Preserve
   local changes and verify the `origin` URL before pulling.
3. Check the Python version and imports without starting the robot:

   ```bash
   cd ~/robo-doge/code/server
   python3 --version
   python3 -m py_compile *.py
   python3 -c "import smbus2, spidev, gpiozero; print('core imports ok')"
   ```

4. Inspect the Freenove connection board revision and Raspberry Pi model. The
   server's `parameter.py` expects a `params.json` containing `Pcb_Version` of
   `1` or `2` and detects the Pi generation. Do not invent the PCB revision.
5. Check the I2C device address and servo board wiring using the documented
   hardware-debugger read-only procedure. A device node does not prove that a
   connected circuit is electrically safe.
6. Only after the preceding checks pass, run the headless server on a raised,
   supported robot with the battery and emergency stop plan understood.
7. From the desktop client, update `code/client/IP.txt` to the confirmed Pi
   address, then test connection before enabling video or motion controls.

## Do not run the bundled installer blindly

`code/setup.py` is a vendor installer, not a harmless dependency check. It:

- changes `/usr/bin/python` by removing it and linking it to `python3`;
- runs `sudo apt-get update`;
- installs bundled libraries globally with `sudo`;
- installs system packages with `apt-get`.

Review the Pi's existing packages first. The hardware-debugger baseline reports
that the current hub already has the core packages used for initial discovery,
including `python3-serial`, `python3-smbus2`, `python3-spidev`, `python3-gpiozero`,
`python3-libgpiod`, `gpiod`, `i2c-tools`, `usbutils`, and `python3-pyudev`.
Installing anything else requires an explicit package decision and should be
recorded as a separate evidence event.

## Debugging record

For each session record the UTC start/end time, operator, target, repository
revision, power and wiring assumptions, exact commands, exit codes, raw output,
interpretation, and next action. Keep passwords, private keys, host secrets,
board serial numbers, and unrelated personal data out of this repository.

The initial 2026-09-07 connection attempts were:

```text
ssh -4 ... thareos@Xark
Result: Could not resolve hostname xark: No such host is known.

ssh -4 ... thareos@10.0.0.96
Result: connect to host 10.0.0.96 port 22: Connection timed out.
```

Interpretation: those failures were caused by the Pi being on a different
Wi-Fi network at the time. SSH reachability was later restored.

## Wi-Fi follow-up: 2026-09-07

The laptop was moved to another Wi-Fi network and retested. The laptop received
`10.0.0.11/24` with gateway `10.0.0.1`, which is the same subnet as the last
known Pi address. The following read-only network checks still failed:

```text
Resolve-DnsName Xark
Result: no DNS result

Resolve-DnsName Xark.local -Type A
Result: no mDNS result

Test-NetConnection 10.0.0.96 -Port 22
Result: DestinationHostUnreachable; ARP entry remained Incomplete

TCP/22 discovery across 10.0.0.1-254
Result: no responsive SSH hosts found
```

Interpretation: the Pi is not currently discoverable on the laptop's active
Wi-Fi. Before another software attempt, check that the Pi is powered and has
joined this exact SSID, then read its address from the router/DHCP client list
or a local display/console. Also check client isolation or guest-network
settings, which can prevent peer-to-peer SSH even when both devices appear to
be online. Once an address is confirmed, repeat the key-only SSH connection and
the read-only baseline above.

## Successful reconnect and software setup: 2026-09-07

The Pi became reachable later on the same date. `Xark` resolved through local
name discovery to `10.0.0.96`, and key-only SSH succeeded as `thareos`.

The read-only baseline reported:

- Debian GNU/Linux 13.6 (trixie), kernel `6.18.39+rpt-rpi-v8`, `aarch64`;
- 48 GB available on the root filesystem and 3.4 GiB memory available;
- temperature `38.9 C` and `throttled=0x0`;
- no failed systemd units;
- GPIO chip devices and I2C devices `/dev/i2c-20` and `/dev/i2c-21` present;
- no Robo-Doge checkout existed before setup.

The repository was cloned to `/home/thareos/robo-doge` from the personal
`origin` `https://github.com/brkpplr/robo-doge.git`. It was clean on
`master` at commit `1264525`.

The Linux checkout contains both `code` and `Code` paths. The runtime paths are
lowercase: `code/server` and `code/client`. Commands using `Code/server` or
`Code/client` silently checked the wrong directories on Linux, so always verify
path casing before running validation.

The Pi setup uses an isolated environment at `/home/thareos/robo-doge/.venv`
with system site packages enabled. The bundled `rpi_ws281x` and `mpu6050`
libraries were installed into that environment. These checks passed:

```bash
cd ~/robo-doge
python3 -m compileall -q code/server
python3 -m compileall -q code/client
cd code/server
../../.venv/bin/python -c 'import Server; print("Server module import ok")'
```

The final server module import succeeded. The desktop client import still needs
OpenCV (`cv2`), which should be installed and tested on the desktop client
environment rather than added to the Pi merely to validate the server.

No server process was started and no servo, GPIO, I2C, SPI, camera, LED, or
other robot-control operation was issued. Import validation is software-only;
it does not prove that the robot wiring, PCB revision, I2C addresses, battery,
or servo calibration are correct. The next physical test requires explicit
board/power verification and a supported, raised robot platform.

## Calibration safety update: 2026-09-07

Calibration no longer sends `CMD_MOVE_STOP` when its window opens. The previous
behavior moved all legs toward the fixed stop pose before calibration began.
The updated flow reads the PCA9685 PWM registers, converts the commanded servo
angles back into the current leg coordinates, and returns that pose to the
client through `CMD_CALIBRATION#current`. Calibration controls remain disabled
until a valid pose is received. If the PWM state cannot be read, the client
reports that the current pose is unavailable instead of issuing a preset move.

Calibration adjustments send the complete four-leg pose through
`CMD_CALIBRATION#preview#...`. The server applies that pose through the normal
inverse-kinematics and servo output path, without inserting the default stop
pose first. Save sends all 12 coordinates in one `CMD_CALIBRATION#save` message;
the server recalculates and persists calibration data. Use preview only with
the robot supported and the legs clear, because each XYZ button can actuate all
servos needed to reach the new pose.

Server startup also no longer calls `relax(True)`, which previously commanded a
relaxation pose during initialization. No server or motion command has been run
with this change yet.

## Hardware blocker found during smoke test: 2026-09-07

The bounded server smoke test reached `Servo -> PCA9685` but failed because
`/dev/i2c-1` is absent. The Pi currently exposes `/dev/i2c-20` and
`/dev/i2c-21`, both identified as HDMI I2C nodes. A targeted read of the
expected PCA9685 address `0x40` returned `Errno 121` (remote I/O error) on both
buses. The ARM I2C setting is commented out in `/boot/firmware/config.txt`.

The operator authorized enabling ARM I2C and confirmed that the raised robot is
connected and clear for a future test. The attempted noninteractive command
was blocked because `sudo` requires the Pi account password. Enter the password
directly in an interactive Pi console or SSH terminal, never in chat:

```bash
sudo raspi-config nonint do_i2c 0
sudo reboot
```

After reboot, reconnect and run the read-only PCA9685 `0x40` probe before
starting the server or issuing any movement command. Do not substitute an HDMI
I2C bus for bus `1` without confirming the robot board is electrically attached
to that bus.

## Post-reboot I2C and startup test: 2026-09-07

After the operator ran the two commands above, the Pi reported:

- `/dev/i2c-1` present, with `dtparam=i2c_arm=on` in the active firmware
   configuration;
- PCA9685 address `0x40` responded on bus `1` with `MODE1=0x11`;
- buses `20` and `21` remained HDMI I2C buses and did not respond at `0x40`;
- MPU6050 address `0x68` and ADS7830 address `0x48` responded to identification
   reads.

The bounded server smoke test did not complete. PCA9685 initialization passed,
then the MPU6050 calibration loop failed intermittently with I2C `Errno 5`
(`Input/output error`) or `Errno 121` (`Remote I/O error`) while reading gyro
registers. A standalone driver test can wake the MPU6050 and obtain individual
samples, but a 100-sample loop is not stable. Treat the IMU wiring, power,
connector seating, and sensor board as the next hardware investigation. Do not
work around this by skipping IMU initialization or by issuing motion commands.

## Powered connection retest: 2026-09-07

After the robot connection board was powered, all expected devices responded on
bus `1`:

- PCA9685 `0x40`: `MODE1=0x10`;
- MPU6050 `0x68`: `WHO_AM_I=0x68`;
- ADS7830 `0x48`: read succeeded.

The MPU6050 driver woke the sensor, applied the configured ranges, and completed
100 calibration-length samples with nonzero accelerometer and gyro data. The
bounded server smoke test then remained running for 8 seconds and exited with
the expected timeout status `124`. This confirms complete server hardware
initialization and TCP startup without a client or movement command.

The read-only `CMD_CALIBRATION#current` request returned
`CMD_CALIBRATION#unavailable` during the first protocol test, so no preset pose
or servo movement was issued. A later controller-only read reconstructed a
valid pose, but the rear legs were asymmetric. The rear channels were:

```text
channels 8, 9, 10:  approximately 84, 120, 51 degrees
channels 11, 12, 13: approximately 102, 91, 18 degrees
```

Channel `13` is at the software minimum while the matching rear channels are
not. This points to rear servo horn/linkage alignment or a saved calibration
offset, rather than an I2C or IMU failure. Do not run another calibration-save,
stop, relax, or walking command until the robot is supported and the rear
linkages are inspected.

## GPIO cleanup blocker: 2026-09-07

A subsequent server start failed while importing `Buzzer.py`: `lgpio` reported
`GPIO busy` for GPIO17. No Robo-Doge process remained and ports `5001` and
`8001` had no listeners afterward, but `gpioinfo` still reported GPIO17 as an
output without an identifiable consumer. Do not bypass the buzzer, forcibly
claim the pin, or start motion until the GPIO owner is identified or the Pi is
cleanly rebooted and server startup is repeated.

## ADC channel and battery-path diagnosis: 2026-09-07

A read-only device probe was run while the Pi was reachable as `Xark` at
`10.0.0.96`. The Pi reported `throttled=0x0`, the MPU6050 returned
`WHO_AM_I=0x68`, the camera was listed as an `ov5647`, and the PCA9685 at
`0x40` responded. These checks do not show a Pi undervoltage or I2C device
failure.

The ADS7830 scan produced these median readings using the existing project
conversion (`raw / 255 * 5 * 2`):

```text
channel 0: raw 133 -> 5.22 V
channel 1: raw 181 -> 7.10 V
channel 2: raw 188 -> 7.37 V
channel 3: raw 203 -> 7.96 V
channel 4: raw 202 -> 7.92 V
channel 5: raw 176 -> 6.90 V
channel 6: raw 191 -> 7.49 V
channel 7: raw 195 -> 7.65 V
```

Channel 0 was stable around `5.22 V`; the other channels varied substantially
between samples and are not confirmed battery measurements. The server
currently calls `self.adc.power(0)`, so it is definitely reporting channel 0.
The result is consistent with channel 0 being connected to the regulated 5 V
rail, or with the battery sense divider not being connected to that channel.
Do not change the software to use another channel based only on this scan;
identify the board schematic or trace the battery divider with power removed,
then verify the candidate channel using a multimeter.

The probe also found an old `main.py -n -t` process with no TCP listeners;
that process held GPIO17 through the buzzer. It was stopped, and GPIO17 is now
no longer claimed by `lg`. A clean server start should be performed only after
the battery input, regulated 5 V rail, and ADC channel are independently
measured.