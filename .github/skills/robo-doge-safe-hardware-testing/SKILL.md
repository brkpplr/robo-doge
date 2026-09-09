---
name: robo-doge-safe-hardware-testing
description: 'Plan and report safe physical tests for robo-doge servos, calibration, sensors, and startup changes. Use whenever a command may energize or move the robot.'
argument-hint: 'Describe the proposed test, robot support, power state, operator position, and emergency stop method.'
---

# Robo-Doge Safe Hardware Testing

Use this skill before any test that can move servos, energize a motor rail, or exercise a loaded peripheral.

## Preflight

1. Confirm the exact repository revision and command to run.
2. Raise or support the robot so legs cannot catch a surface. Clear the workspace and keep hands, cables, and tools away from joints.
3. Confirm the operator is present, understands the expected motion, and can disconnect power immediately.
4. Verify power assumptions separately: battery state, servo rail, Pi supply, common ground, and any uncertain telemetry.
5. Start with one leg, one axis, or the smallest supported motion. Prefer preview or dry-run paths before a gait.

## During and after

- Stop immediately for unexpected direction, excessive travel, stalled servos, heat, brownouts, repeated exceptions, or mechanical binding.
- Use one Ctrl+C and wait for cleanup. Repeated Ctrl+C can interrupt shutdown handling.
- After stopping, verify process ownership and leave the robot unpowered unless another test is explicitly planned.
- Record revision, exact command, support arrangement, power measurements, expected result, observed result, and next action.

SSH success, a TCP response, and a clean Python compile do not prove that physical motion is safe.