---
name: robo-doge-client-server-debugging
description: 'Trace robo-doge desktop client, TCP command, video, and server control failures. Use for refused connections, commands that acknowledge but do not move hardware, protocol mismatches, or noisy startup logs.'
argument-hint: 'Describe the client action, port, exception, server output, and expected hardware effect.'
---

# Robo-Doge Client-Server Debugging

Trace one protocol path at a time: client UI, command serialization, server dispatch, controller state, and hardware output.

## Procedure

1. Test TCP control port 5001 and optional video port 8001 independently. `WinError 10061` means the target refused the connection or no listener exists; it does not by itself identify the wrong address.
2. Compare command constants and payload delimiters in `code/client/Command.py` and `code/server/Command.py`.
3. For a command that reaches the server but has no motion, inspect dispatch, pose mutation, relax state, `Control.run()`, channel mapping, and physical power in that order.
4. For calibration, verify `current`, `preview`, and `save` semantics rather than treating a successful socket write as movement proof.
5. Preserve partial-initialization handling: `Client.connection` must exist before video setup, and failed video setup must close available sockets without hiding control errors.
6. Remove repetitive logs only after keeping actionable camera, connection, and exception diagnostics.

Validate the touched Python slice with `python -m py_compile` and report software results separately from physical motion.