# Upgrading to a new Home Manager release {#sec-upgrade-release}

## Overview {#sec-upgrade-release-overview}

When upgrading NixOS to a new major version (e.g., from 24.11 to
25.05), you also need to upgrade your Home Manager channel to maintain
compatibility. This guide covers the proper steps to upgrade Home
Manager channels for NixOS 25.05.

## Understanding Home Manager Versioning {#sec-upgrade-release-understanding-versioning}

Home Manager follows NixOS release cycles and provides corresponding branches:

- **release-##.##**: Stable branch for NixOS ##.## (current stable)

- **master**: Development branch (tracks nixos-unstable)

:::{.note}
Always use the Home Manager version that matches your NixOS version to
avoid compatibility issues.
:::

## Channel-Based Installation (Traditional) {#sec-upgrade-release-understanding-channel}

1. First, verify your current Home Manager channel:

   ``` shell
   $ nix-channel --list
   ```

   You should see something like:

   ```
   home-manager https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz
   ```

1. Update the Home Manager channel to a NixOS 25.05 compatible version:

   ``` shell
   $ nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
   $ nix-channel --update
   ```

1. Apply the changes:

   ``` shell
   $ home-manager switch
   ```

## Flake-Based Installation (Modern) {#sec-upgrade-release-understanding-flake}

If you're using Home Manager with Nix flakes, update your `flake.nix`:

```nix
{
  description = "Home Manager configuration";

  inputs = {
    # Increment release branch for NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
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

Then update and rebuild. If you are using Home Manager standalone:

``` shell
$ nix flake update
$ home-manager switch --flake .
```

And if you are using Home Manager as a NixOS module then you will need
to update your system configuration instead and run

``` shell
$ nix flake update
$ sudo nixos-rebuild switch
```

## State Version Management {#sec-upgrade-release-state-version}

:::{.warning}
Careful updating your `home.stateVersion` when upgrading Home Manager.
:::

The `stateVersion` is best to remain set to the NixOS version you
**first installed** Home Manager

```nix
{
  home.stateVersion = "24.11";  # Example: if you first installed on 24.11
}
```

**Why?** The `stateVersion` ensures backward compatibility and
prevents breaking changes from affecting your existing configuration.

**Remember:** Channel version is not the same as State version. Update
the channel, keep the `stateVersion` unchanged. Advanced users can
view the changes between releases and see if any of the `stateVersion`
changes will affect them and increment, if they migrate their
configurations to follow the changed evaluation.

## Troubleshooting {#sec-upgrade-release-state-troubleshooting}

### Common Issues {#sec-upgrade-release-state-troubleshooting-common-issues}

Check the [Home Manager Release Notes](#ch-release-notes) for breaking changes.

1. **Version Mismatch Warning**: If you see warnings about version
   mismatches, ensure your Home Manager version matches your NixOS
   version.

1. **Module Changes**: Modules are constantly being updated with new
   features to keep up with changes in upstream packaging or to fix
   bugs and add features. If you have an unexpected change, check if
   there was something noted in the release notes or news entries.

1. **Channel Not Found**: If `nix-channel --list` shows no channels,
   you might be using a different installation method (like flakes or
   NixOS module).

### Verification {#sec-upgrade-release-state-troubleshooting-verification}

After upgrading, verify the installation:

``` shell
$ home-manager --version
```

This should show version 25.05 or indicate it's using the release-25.05 branch.

## Additional Resources {#sec-upgrade-release-resources}

- [NixOS Stable Release Notes](https://nixos.org/manual/nixos/stable/release-notes)
- [Home Manager Release Notes](#ch-release-notes)
