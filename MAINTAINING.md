# Maintaining Home Manager

This file is intended as a reference for Home Manager's core maintainers,
although it may be interesting for anyone curious how we do certain things.

## Releasing

Home Manager releases stable versions in sync with NixOS/nixpkgs. A _`YY.05`_
version is released in May and a _`YY.11`_ version is released in November.

We do not need to wait for the release to come out of _"beta"_ before creating a
branch, however we _should_ wait before updating links and references on the
`master` branch.

Creating a stable branch may require temporarily disabling branch protection.
This can only be done by an "admin" or "owner".

Once a stable branch is created, its flake inputs should be updated to point to
the corresponding stable versions. The branch can be created before these exist,
in which case they should be updated when the corresponding stable inputs become
available.

Once a stable version is considered "out of beta", references to Home Manager's
stable branch should be updated on the `master` branch to reference the new
version.

### Release Workflow

The release process involves four phases in a specific order:

1. **On master - Mark current as stable**: Update all documentation and examples
   to reflect the current release (e.g., 25.11) as stable, removing "(unstable)"
   tags
2. **Cut the release branch**: Create the new release branch from master (e.g.,
   `release-25.11`)
3. **On release branch - Mark as release branch**: Set `isReleaseBranch: true`
   in `release.json`
4. **On master - Prepare for next**: Bump version to next release (e.g., 26.05)
   and add "(unstable)" tag back

**Important**: The `isReleaseBranch` field in `release.json` is managed
differently on each branch:

- On **master**: Always remains `false`
- On **release branches**: Set to `true` in a separate commit after cutting the
  branch from master

This workflow ensures that the release branch captures a stable snapshot of
master, which then moves forward to the next development cycle.

### Release Preparation Checklist

#### Step 1: On master - Mark Current as Stable

**When**: When ready to cut a new release branch (e.g., when preparing to
release 25.11)

Reference commits:

- `e08e6e2389234000b0447e57abf61d8ccd59a68e` (home-manager: set 25.05 as stable)

1. **README.md**
   - Update example release branch references (e.g., `release-24.11` →
     `release-25.05`)
   - Update current stable version references (e.g., `24.11` → `25.05`)

2. **docs/manual/installation/nix-darwin.md**
   - Update channel version in example commands
   - Update `home.stateVersion` in examples

3. **docs/manual/installation/nixos.md**
   - Update channel version in example commands
   - Update tarball URLs
   - Update `home.stateVersion` in examples

4. **docs/manual/installation/standalone.md**
   - Update channel version in example commands

5. **docs/manual/manual.md**
   - Remove `(unstable)` suffix from version

6. **docs/manual/nix-flakes/standalone.md**
   - Update flake references (e.g., `home-manager/release-24.11` →
     `home-manager/release-25.05`)
   - Update `$branch` examples

7. **docs/manual/usage/configuration.md**
   - Update `home.stateVersion` in example configurations

8. **docs/release-notes/rl-YYMM.md**
   - Replace "This is the current unstable branch and the information in this
     section is therefore not final."
   - With: "The YY.MM release branch became stable in <Month>, YYYY."

9. **home-manager/home-manager** script
   - Update default `home.stateVersion` in generated configurations
   - Update `home.stateVersion` in uninstall function

10. **modules/misc/uninstall.nix**
    - Update `home.stateVersion` in uninstall config

**Note**: Do NOT change `isReleaseBranch` in `release.json` - keep it as `false`

#### Step 2: Cut the release branch

**When**: After Step 1 is merged to master

1. Create the new release branch from master
   - Example: `git checkout -b release-25.11 master`
2. Push the branch to the repository

#### Step 3: On the release branch - Mark as Release Branch

**When**: Immediately after creating the release branch

Reference commits:

- `70a787cc5` (release: set release branch)

1. **release.json**
   - Change `isReleaseBranch` from `false` to `true`
   - Do NOT change the `release` field (it's already correct from Step 1)

2. **flake.nix**
   - Update the nixpkgs input to track the corresponding stable branch
   - Example: For `release-25.11`, change from:
     ```nix
     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     ```
     to:
     ```nix
     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
     ```
   - Run `nix flake update` to update flake.lock to the stable branch
   - Commit the flake.nix and flake.lock changes

**Note**: The release branch should track the stable NixOS release channel
(e.g., `nixos-25.11`), while master continues to track `nixos-unstable`.

#### Step 3.5: On master - Update CI for the New Release Branch

**When**: After marking the release branch as a release branch (Step 3)

**Where**: On the **master** branch (CI workflows run from master)

**What**: Update GitHub Actions workflows to include the new stable branch

1. **.github/workflows/update-flake.yml** (on master)
   - Replace the old stable branch with the new release branch in the matrix
   - Example: When creating `release-25.11`, update the matrix from:

     ```yaml
     strategy:
       matrix:
         branch: [master, release-25.05]
     ```

     to:

     ```yaml
     strategy:
       matrix:
         branch: [master, release-25.11]
     ```

   - This ensures automated flake.lock updates run on the current stable branch
   - Note: We only maintain CI for the latest stable release, not older releases

2. **.github/dependabot.yml** (on master)
   - Replace the old stable branch with the new release branch
   - Example: When creating `release-25.11`, update the target-branch from:

     ```yaml
     - package-ecosystem: "github-actions"
       directory: "/"
       target-branch: "release-25.05"
       schedule:
         interval: "weekly"
       commit-message:
         prefix: "ci:"
     ```

     to:

     ```yaml
     - package-ecosystem: "github-actions"
       directory: "/"
       target-branch: "release-25.11"
       schedule:
         interval: "weekly"
       commit-message:
         prefix: "ci:"
     ```

   - This ensures automated dependency updates for GitHub Actions on the current
     stable branch
   - Note: We only maintain dependabot for the latest stable release, not older
     releases

**Important**: CI workflows are executed from master, so this change must be
committed to the master branch.

#### Step 4: On master - Prepare for Next Release

**When**: After cutting the release branch, prepare master for the next
development cycle

Reference commits:

- `9a4a9f1d6e43fe4044f6715ae7cc85ccb1d2fe09` (home-manager: prepare 25.11)

1. **docs/release-notes/rl-YYMM.md** (CREATE NEW)
   - Create new release notes file for next version with unstable warning
   - Example: Create `rl-2605.md` when preparing for 26.05

2. **docs/manual/manual.md**
   - Update version to next release with `(unstable)` tag
   - Example: `25.11` → `26.05 (unstable)`

3. **docs/release-notes/release-notes.md**
   - Add new release notes file `rl-YYMM.md` at the top of the chapters list

4. **home-manager/home-manager** script
   - Update `--version` output to next version
   - Example: `echo 25.11-pre` → `echo 26.05-pre`

5. **modules/misc/version.nix**
   - Add new version string to `stateVersion` enum list
   - Example: Add `"26.05"` after `"25.11"`

6. **release.json**
   - Update `release` field to next version (e.g., `"25.11"` → `"26.05"`)
   - **IMPORTANT**: Keep `isReleaseBranch` as `false` on master

### Version State Changes

Each release may introduce state version changes that affect the default
behavior of Home Manager for users who set `home.stateVersion` to that version.

State version changes should be documented in the release notes under a "State
Version Changes" section, explaining what behavior changes for users who set
their state version to the new release.

### Backporting

Stable branches get bug fixes and security updates, but usually not new modules
or features. When backporting:

1. Use `git cherry-pick -x <commit>` to preserve the original commit reference
2. Test that the backport builds successfully
3. Consider whether the change might affect existing stable users
4. Update the PR/commit message to indicate it's a backport

If a user needs a module backported, they should open an issue explaining the
use case.
