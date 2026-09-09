---
name: robo-doge-deployment
description: 'Deploy reviewed robo-doge changes from Windows to the Raspberry Pi and verify the running revision. Use for commit, push, pull, startup, and synchronization workflows.'
argument-hint: 'Describe the change, source revision, target Pi, and whether local Pi edits are expected.'
---

# Robo-Doge Deployment

Windows is the source of truth for intentional code changes. Read `robo-doge/AGENTS.md` before deployment.

## Windows

1. From `C:\Users\bruno\code\robo-doge`, inspect:
   ```powershell
   git status --short --branch
   git remote -v
   git diff --check
   python -m py_compile code\client\Client.py code\client\Main.py code\server\Control.py code\server\Server.py
   ```
2. Review the diff and commit only the requested changes. Push only to personal `origin` on `main`; the workspace `ScriptLib.ps1 --push` workflow is allowed after review.
3. Do not force-push, reset, or discard local work.

## Pi

1. Connect with the configured SSH key and inspect before pulling:
   ```bash
   cd /home/thareos/robo-doge
   git status --short --branch
   git remote -v
   git branch --show-current
   ```
2. Stop if the Pi has local modifications. Pull only with:
   ```bash
   git pull --ff-only origin main
   git log -1 --oneline
   ```
3. Start the server using the documented virtual environment and entry point. Verify control port 5001 separately from optional video port 8001.
4. Report source revision, Pi revision, pull result, startup command, and physical testing status.

Never claim deployment is complete until the Pi revision is verified.