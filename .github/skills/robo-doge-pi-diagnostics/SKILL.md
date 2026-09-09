---
name: robo-doge-pi-diagnostics
description: 'Diagnose Raspberry Pi, I2C, GPIO, process, network, and dependency failures on robo-doge without causing motion. Use for SSH access, missing devices, stale processes, import errors, and server startup failures.'
argument-hint: 'Describe the Pi symptom, host, command output, and whether the robot is powered.'
---

# Robo-Doge Pi Diagnostics

Use this skill for read-only diagnosis on the Raspberry Pi. Read `robo-doge/AGENTS.md` and `robo-doge/docs/raspberry-pi-setup-and-debugging.md` before changing hardware or startup behavior.

## Baseline

1. Confirm the target host and repository path. Use key-only SSH:
   ```powershell
   ssh -4 -i "$env:USERPROFILE\.ssh\id_ed25519_xark" -o PreferredAuthentications=publickey thareos@Xark
   ```
2. On the Pi, collect read-only facts:
   ```bash
   hostname; uname -a; python3 --version
   cd /home/thareos/robo-doge
   git status --short --branch
   pgrep -af 'python|Server|main.py'
   ss -ltnp | grep -E ':5001|:8001'
   vcgencmd get_throttled
   ls -l /dev/i2c-* 2>/dev/null
   ```
3. Run `i2cdetect -y 1` only when the bus and target hardware are known. Expected devices are PCA9685 `0x40`, MPU6050 `0x68`, and ADS7830 `0x48`.
4. Use `gpioinfo` to inspect ownership before touching GPIO. Stop at evidence collection if another process owns the pin.

## Boundaries

- Do not write PWM, GPIO, I2C registers, or calibration files during diagnosis.
- Do not treat SSH reachability as proof that servo power or mechanical safety is good.
- Check the virtual environment and actual import path before changing dependencies.
- Preserve local Pi changes; never use destructive reset or checkout commands.

Report the exact commands, revision, hardware power state, observed output, and the next smallest test.