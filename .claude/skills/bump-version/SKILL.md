---
name: bump-version
description: Bump the app version in pubspec.yaml (patch/minor/major or explicit X.Y.Z) and commit it with the project's convention. Use when the user asks to bump/update/raise the version or prepare a release.
---

# bump-version

1. Make sure the working tree has no unrelated staged changes (`git status --short`).
2. Run: `bash .claude/skills/bump-version/bump.sh <patch|minor|major|X.Y.Z>` (default `patch`). It prints `old -> new`.
3. Run `bash .claude/skills/verify/verify.sh` (analyze + tests).
4. Commit only `pubspec.yaml`, using the existing message convention:
   ```bash
   git add pubspec.yaml
   git commit -m "feat: update version to <new> in pubspec.yaml" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
   ```
5. Do **not** push, tag or build unless the user explicitly asks. The user builds the release APK locally (signed with their local debug keystore so it installs over existing installs) and publishes the GitHub Release manually: tag `X.Y.Z` (no `v`), single asset `KeepInventory-vX.Y.Z-release.apk` — the in-app updater (`github_update_service.dart`) downloads `assets[0]`.

Local release build if asked: `flutter build apk --release` → `build/app/outputs/apk/release/KeepInventory-v<new>-release.apk`.

Choosing the level when the user doesn't say: bug fixes only → patch; new user-visible feature → minor. Check `git log --oneline $(git describe --tags --abbrev=0)..HEAD` if unsure.
