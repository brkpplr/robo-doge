---
name: windows-case-rename-merge-recovery
description: 'Recover Git merges on Windows after case-only renames such as Application/application, Code/code, Client/client, Server/server, or Picture/picture. Use for rename/rename, rename/delete, modify/delete, delete/delete, and file-location conflicts in Freenove robotics repositories.'
argument-hint: 'Describe the conflicted paths and the merge state.'
---

# Windows Case-Rename Merge Recovery

Use this procedure when a case-insensitive Windows worktree cannot represent both the local and upstream path casing.

1. Confirm the target repository and preserve the merge state:
   ```powershell
   git status --short --branch
   git ls-files -u
   git diff --name-only --diff-filter=U
   ```
2. Classify each conflict: rename/rename, rename/delete, modify/delete, delete/delete, or a file moved because its parent directory changed casing.
3. Compare local and upstream versions before choosing a side. Preserve local calibration and compatibility fixes when they are intentional; use upstream for clearly imported documentation or vendor additions.
4. For a normal file, resolve content and stage it with `git add`. Honor intentional deletions with `git rm`.
5. For a case-only path that cannot be checked out normally, inspect the unmerged index entries and obtain the desired blob, commonly stage 3 for upstream:
   ```powershell
   git rev-parse ':3:Code/Server/Server.py'
   git update-index --add --cacheinfo '100644,<blob>,code/server/Server.py'
   ```
   Replace the mode, blob, and path with the actual entry. Verify the result with `git ls-files`.
6. Do not resolve binary files or generated/vendor files by opening them as text. Choose the correct complete artifact and stage it.
7. Finish only when `git diff --name-only --diff-filter=U` is empty. Then review `git diff --cached --stat`, run focused syntax checks, and commit only when explicitly requested.
8. Do not use `git reset --hard`, force-push, or push to `upstream` as a conflict shortcut.
