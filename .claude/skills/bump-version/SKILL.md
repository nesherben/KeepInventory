---
name: bump-version
description: Bump the app version in pubspec.yaml (patch/minor/major or explicit X.Y.Z), commit it, and — after the user confirms — build the release APK locally and publish the GitHub Release (tag + APK). Use when the user asks to bump/update/raise the version, prepare a release, or publish/release the app.
---

# bump-version

## A. Bump
1. Make sure the working tree has no unrelated staged changes (`git status --short`).
2. Run: `bash .claude/skills/bump-version/bump.sh <patch|minor|major|X.Y.Z>` (default `patch`). It prints `old -> new`.
3. Run `bash .claude/skills/verify/verify.sh` (analyze + tests).
4. Commit only `pubspec.yaml`, using the existing message convention:
   ```bash
   git add pubspec.yaml
   git commit -m "feat: update version to <new> in pubspec.yaml" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
   ```

## B. Release (the user has authorised this flow, but **every release needs their explicit OK**)
Releases are never built in CI. The APK to publish is exactly the one `flutter build apk --release` produces locally (signed with the user's local keystore so it installs over existing installs).

1. Push the commits: `git push origin main` (this also triggers the CI test build; that APK is NOT the release).
2. Build: `flutter build apk --release` → `build/app/outputs/apk/release/KeepInventory-v<new>-release.apk` (Gradle renames it; ignore `build/app/outputs/flutter-apk/app-release.apk`).
3. Draft the notes from `git log --oneline <previous tag>..HEAD` (`git tag --sort=-creatordate | head -1`), in Spanish, user-facing, this format:
   ```
   ## Novedades
   - 🎓 ...
   ## Correcciones
   - ...

   **Full Changelog**: https://github.com/nesherben/KeepInventory/compare/<previous tag>...<new>
   ```
   Omit a section if empty; skip chores/docs/refactors unless user-visible. Save it to the scratchpad (e.g. `release-notes-<new>.md`), never in the repo.
4. **Stop and ask**: show version/tag, APK path + size and the notes. Wait for the user's OK.
5. After OK, check then publish:
   ```bash
   bash .claude/skills/bump-version/release.sh <notes.md> --dry-run   # checks only
   bash .claude/skills/bump-version/release.sh <notes.md>             # tag + push tag + gh release
   ```
   The script refuses if: the tree is dirty, HEAD ≠ origin/main, the tag exists, the APK is missing or older than the last commit (`--build` rebuilds), or `gh` is missing / not logged in.
6. Report the release URL that `gh` prints.

Conventions: tag and title `X.Y.Z` (no `v`; older ones like `1.13` are legacy), **single asset** — the in-app updater (`github_update_service.dart`) downloads `assets[0]`.

`gh` lives at `C:\Program Files\GitHub CLI\gh.exe` (the script finds it even if Git Bash's PATH is stale). If it says it is not logged in, ask the user to run `! gh auth login` — never handle their credentials.

Choosing the level when the user doesn't say: bug fixes only → patch; new user-visible feature → minor. Check `git log --oneline $(git describe --tags --abbrev=0)..HEAD` if unsure.
