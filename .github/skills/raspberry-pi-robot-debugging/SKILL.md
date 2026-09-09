---
name: raspberry-pi-robot-debugging
description: 'Debug Freenove Raspberry Pi robots in robo-doge and robo-hexa. Use for servo calibration, PCA9685/PWM failures, GPIO/I2C/SPI, LED and IMU problems, Python import/path casing, client-server commands, gait behavior, and safe bench testing.'
argument-hint: 'Describe the robot model, symptom, recent change, and observed output.'
---

# Raspberry Pi Robot Debugging

Debug from the power and wiring boundary toward application behavior.

## Procedure

1. Identify the robot model, board revision, Raspberry Pi OS/Python version, and exact symptom. Do not assume dog and hexapod pin maps or gait constants are interchangeable.
2. Connect to the hardware-debug hub with `ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" -o PreferredAuthentications=publickey thareos@Xark`. The Pi is `Xark` at `10.0.0.96` on the private Wi-Fi network; do not place the password or private key in repositories, scripts, or chat.
3. Reproduce without live motion when possible. Disconnect loads or use a dry-run/logging path before commanding servos or motors.
4. Check physical prerequisites: power supply, common ground, I2C enablement, device address, board connection, GPIO numbering mode, and measured voltage. Verify pinout from the repository documentation.
5. Trace the software path from the entry point through configuration, client/server messaging, controller, servo driver, and hardware library.
6. Verify the installed dependency and its actual API before changing imports. In particular, distinguish `Adafruit_PCA9685` with `set_pwm_freq`/`set_pwm` from `PCA9685` with `setPWMFreq`/`setPWM`; do not mix APIs based on naming alone.
7. Check servo channel mapping, pulse range, calibration offsets, neutral pose, PWM frequency, and bounds before changing gait or motion code.
8. For LEDs, IMUs, camera, and optional sensors, isolate the feature and test a minimal import/device probe. An optional peripheral failure should not obscure core motion diagnosis.
9. On Windows development machines, respect Python import casing and repository path casing even though the local filesystem may hide errors that fail on Linux.
10. Make one small change, run `python -m py_compile` or the narrowest available test, and record the exact command/output. Report physical testing separately from software validation.

## Safety

- Never run an unknown motion script on a powered robot.
- Keep hands clear and use a raised, supported test platform for servo tests.
- Stop on brownouts, overheating, stalled servos, unexpected movement, or repeated driver exceptions.
- Do not infer a wiring correction solely from a Python exception.
