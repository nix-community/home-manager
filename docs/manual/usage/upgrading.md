# Upgrading to a new Home Manager release {#sec-upgrade-release}

## Overview {#sec-upgrade-release-overview}

When moving your configuration to a new Nixpkgs release branch, you
should also move Home Manager to the matching release branch. On NixOS
this usually means upgrading Home Manager together with NixOS. On
standalone and nix-darwin installations, match Home Manager to the
Nixpkgs branch used by your configuration. The examples below use 25.11;
replace this with the release branch you are upgrading to.

If your configuration follows `nixos-unstable` or `nixpkgs-unstable`,
use Home Manager's `master` branch.

## Understanding Home Manager Versioning {#sec-upgrade-release-understanding-versioning}

Home Manager follows NixOS release cycles and provides corresponding branches:

- **release-<version>**: Stable branch for the matching NixOS or
  Nixpkgs release, such as `release-25.11`.

- **master**: Development branch (tracks nixos-unstable)

:::{.note}
Use the Home Manager branch that matches the Nixpkgs branch used to
evaluate your Home Manager configuration. For stable NixOS
configurations, this is normally the same as your NixOS version.
:::

## Flake-Based Installation {#sec-upgrade-release-understanding-flake}

If you are using Home Manager with Nix flakes, update your `nixpkgs` and
`home-manager` inputs together:

```nix
{
  description = "Home Manager configuration";

  inputs = {
    # Match the Nixpkgs branch to the release you are using.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      # Match the Home Manager branch to the Nixpkgs branch above.
      url = "github:nix-community/home-manager/release-25.11";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
```

For `nixos-unstable` or `nixpkgs-unstable`, use the `master` branch
instead:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
    };
  };
}
```

Then update the lock file and rebuild using the command for your
installation method.

For a standalone Home Manager flake:

``` shell
$ nix flake update
$ home-manager switch --flake .
```

For Home Manager as a NixOS module:

``` shell
$ nix flake update
$ sudo nixos-rebuild switch --flake .
```

For Home Manager as a nix-darwin module:

``` shell
$ nix flake update
$ darwin-rebuild switch --flake .
```

These commands assume that your current directory is the flake. If not,
pass the flake path or URI with `--flake <flake-uri>`.

## Channel-Based Installation {#sec-upgrade-release-understanding-channel}

For a standalone channel-based installation, first verify your current
Home Manager channel:

``` shell
$ nix-channel --list
```

The entry identifies the Home Manager branch currently in use. For
example:

```
home-manager https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz
```

Update the Home Manager channel to the branch matching your Nixpkgs
release, then switch:

``` shell
$ nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
$ nix-channel --update
$ home-manager switch
```

When Home Manager is installed as a NixOS module with channels, update
the root user's Home Manager channel and rebuild the system:

``` shell
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
$ sudo nix-channel --update
$ sudo nixos-rebuild switch
```

When Home Manager is installed as a nix-darwin module with channels,
update the Home Manager channel used by your nix-darwin configuration
and rebuild the system:

``` shell
$ nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
$ nix-channel --update
$ darwin-rebuild switch
```

## State Version Management {#sec-upgrade-release-state-version}

:::{.warning}
Careful updating your `home.stateVersion` when upgrading Home Manager.
:::

The `stateVersion` should remain set to the Home Manager release you
first used for this home configuration.

```nix
{
  # Example: if this home configuration was first created on 24.11.
  home.stateVersion = "24.11";
}
```

**Why?** The `stateVersion` ensures backward compatibility and
prevents breaking changes from affecting your existing configuration.

**Remember:** Channel or flake input version is not the same as state
version. Update Home Manager, keep `home.stateVersion` unchanged, and
only change it after reading the release notes and migrating any
affected configuration.

## Troubleshooting {#sec-upgrade-release-state-troubleshooting}

### Common Issues {#sec-upgrade-release-state-troubleshooting-common-issues}

Check the [Home Manager Release Notes](#ch-release-notes) for breaking changes.

1. **Version Mismatch Warning**: If you see warnings about version
   mismatches, ensure your Home Manager branch matches the Nixpkgs
   branch used by your configuration. For NixOS stable releases, this
   usually means matching your NixOS version.

1. **Module Changes**: Modules are constantly being updated with new
   features to keep up with changes in upstream packaging or to fix
   bugs and add features. If you have an unexpected change, check if
   there was something noted in the release notes or news entries.

1. **Channel Not Found**: If `nix-channel --list` shows no channels,
   you might be using a different installation method, such as flakes,
   or Home Manager may be imported through your system configuration.

### Verification {#sec-upgrade-release-state-troubleshooting-verification}

After upgrading, verify the installation:

``` shell
$ home-manager --version
```

This should show the Home Manager version or indicate that it is using
the expected release branch.

## Additional Resources {#sec-upgrade-release-resources}

- [NixOS Stable Release Notes](https://nixos.org/manual/nixos/stable/release-notes)
- [Home Manager Release Notes](#ch-release-notes)
