---
name: robo-doge-power-and-rail-diagnostics
description: 'Diagnose robo-doge battery, ADC, Raspberry Pi 5 V, PCA9685, and servo rail problems. Use for low-voltage messages, brownouts, resets, weak servos, or uncertain battery telemetry.'
argument-hint: 'Describe measured voltages, ADC channel, load state, symptoms, and board power connections.'
---

# Robo-Doge Power and Rail Diagnostics

Use measurements and the documented board wiring, not software labels alone. Read the runbook before changing ADC conversion or shutdown behavior.

## Known ambiguity

The current ADC channel 0 reading is about 5.22 V under the existing conversion and may represent a regulated 5 V rail rather than the two-cell battery. A two-cell pack is about 7.4 V nominal and 8.4 V full. Do not switch to channel 7 based only on an address scan.

## Procedure

1. Record battery state, charger state, robot load, Pi symptoms, and the exact ADC channel/conversion.
2. With power off where appropriate, inspect common ground, connectors, regulator wiring, PCA9685 supply, and servo distribution.
3. With a multimeter, measure battery input, PCA9685/servo rail, Raspberry Pi 5 V, and each ADC candidate relative to ground. Compare those values to software telemetry.
4. Check `vcgencmd get_throttled` and logs for undervoltage or resets, but do not treat them as a substitute for measurements.
5. Do not restore low-voltage shutdown, alter conversion constants, or move ADC channels until the sense path is traced and measured.

## Safety

Disconnect power before rewiring. Keep the robot supported during loaded tests. Stop on heat, brownouts, smell, unstable servos, or battery damage. Report measured values, meter location, load condition, and revision.