---
name: robo-doge-calibration
description: 'Work on robo-doge leg calibration, pose preview, servo offsets, and calibration persistence. Use when XYZ controls do not move legs, saved offsets are wrong, or front and rear channels behave asymmetrically.'
argument-hint: 'Describe the leg, axis, current pose, expected movement, and whether the robot is physically supported.'
---

# Robo-Doge Calibration

Read `robo-doge/AGENTS.md` and the runbook before changing calibration behavior. Calibration preview actuates hardware.

## Model

- `point` is the current commanded pose.
- `calibration_point` is the persisted reference used to derive offsets.
- `CMD_CALIBRATION#current` requests the current pose.
- `CMD_CALIBRATION#preview#<12 values>` replaces the live pose and calls the controller run path.
- `CMD_CALIBRATION#save#<12 values>` persists the reference and recalculates offsets; save is not a substitute for preview.

## Procedure

1. Verify client and server command constants match and inspect the complete 12-value payload.
2. Change one leg and one axis at a time. Confirm the client sends `preview`, the server replaces the pose, relax state is disabled, and `Control.run()` reaches PWM output.
3. Check channel mapping, sign conventions, software limits, neutral pose, pulse range, and rear-leg asymmetry before changing constants.
4. Save only after the physical pose is correct. Confirm the persisted file and reload behavior separately.
5. Record the leg, axis, old/new values, revision, command payload shape, and physical result.

## Safety

Use a raised, supported robot with clear legs and an emergency power disconnect. Never infer calibration correctness from a successful TCP response alone. Stop on unexpected movement, stalled servos, brownouts, or mechanical binding.