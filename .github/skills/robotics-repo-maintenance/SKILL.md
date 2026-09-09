---
name: robotics-repo-maintenance
description: 'Maintain and debug the robo-doge and robo-hexa Raspberry Pi robotics repositories. Use for upstream synchronization, Git remote safety, Windows case-only merge conflicts, Python hardware-control debugging, calibration, PCA9685/LED issues, IP configuration, and validating robot changes before pushing.'
argument-hint: 'Describe the robotics repository, hardware symptom, or upstream synchronization task.'
---

# Robotics Repository Maintenance

Use this skill for the two Freenove-derived Raspberry Pi robotics repositories in this vault:

- `robo-doge`: quadruped Robot Dog Kit. Main code is under `code/client`, `code/server`, and `application`.
- `robo-hexa`: Big Hexapod Robot Kit. Main code is under `code/Client`, `code/Server`, `code/Libs`, and `application`.

## Remote Safety

1. Confirm the working directory is the target repository before running Git commands.
2. Inspect `git remote -v`, branch tracking, and `git status --short --branch`.
3. Keep `origin` pointed at the user's personal repository:
   - `https://github.com/brkpplr/robo-doge`
   - `https://github.com/brkpplr/robo-hexa`
4. Keep the official Freenove repository as `upstream`:
   - `https://github.com/Freenove/Freenove_Robot_Dog_Kit_for_Raspberry_Pi.git`
   - `https://github.com/Freenove/Freenove_Big_Hexapod_Robot_Kit_for_Raspberry_Pi.git`
5. Use `git fetch upstream --prune` to inspect upstream work. A plain `git push` must target `origin`, never Freenove.
6. Do not force-push, reset, discard local work, or commit for the user unless explicitly requested.

## Upstream Synchronization

1. Inspect local-only and upstream-only commits before merging:
   ```powershell
   git log --oneline master..upstream/master
   git log --oneline upstream/master..master
   ```
2. Merge only after checking the worktree and preserving local commits:
   ```powershell
   git merge upstream/master
   ```
3. Expect structural conflicts on Windows when local history renamed `Application`, `Code`, or `Picture` to lowercase paths. Also expect server/client path conflicts when Freenove adds files under the original casing.
4. Resolve each conflict intentionally. Prefer upstream for files that are being updated from Freenove, but preserve local hardware fixes and personal documentation when they remain relevant. Do not apply `checkout --theirs` blindly to files with local behavior changes.
5. If Windows leaves a stage 1/stage 3 case-only conflict after normal checkout, inspect the stage 3 blob with `git ls-files -u` and resolve the index with `git update-index --cacheinfo`; do not use a destructive reset.
6. Verify `git diff --name-only --diff-filter=U` is empty before committing.
7. Treat `git diff --check` warnings in imported generated/vendor files as upstream findings to report, not as a reason to rewrite vendor code without authorization.

## Hardware Debugging

1. Read the repository README and identify the robot model before changing control code.
2. Trace the path from configuration to hardware output: IP/point files, client/server entry points, control modules, servo/PCA9685 drivers, and LED/IMU modules.
3. Prefer static checks and a single-device or dry-run path before commanding servos, motors, LEDs, or power-hungry peripherals.
4. Check calibration bounds, PWM frequency, channel mapping, I2C address, dependency imports, and exception handling before changing motion behavior.
5. Treat bundled Windows executables, DLLs, `.pyd` files, PDFs, and generated libraries as opaque artifacts. Do not edit binary artifacts as text.
6. Never infer a hardware wiring, voltage, or pinout change from a software symptom alone; verify the repository documentation and board revision first.

## Validation Checklist

- `git status --short --branch` shows the intended state.
- `git diff --name-only --diff-filter=U` returns no paths.
- Python files in the touched slice pass `python -m py_compile` or a focused test where dependencies permit.
- Configuration changes are reviewed for target IP, port, board revision, and calibration values.
- The final push URL is checked with `git remote get-url --push origin`.
- Report any untested physical behavior explicitly; software validation cannot prove safe robot motion.
