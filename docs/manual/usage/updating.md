# Updating {#sec-updating}

Updating means moving to a newer revision of the Home Manager branch
that your configuration already follows. For example, a configuration
using `release-25.11` can update to a newer revision of `release-25.11`
without changing release branches.

If you want to move from one release branch to another, such as
`release-25.05` to `release-25.11`, or between a release branch and
`master`, see
[Upgrading to a new Home Manager release](#sec-upgrade-release).

## Flake-Based Configurations {#sec-updating-flakes}

Flake inputs are pinned in `flake.lock`, and Home Manager will keep using
the pinned revisions until you update that lock file.

To update all inputs in the flake:

``` shell
$ nix flake update
```

To update only specific inputs, name them explicitly:

``` shell
$ nix flake update home-manager nixpkgs
```

These commands assume that your current directory is the flake. If not,
pass the flake path or URI with `--flake <flake-uri>`.

After updating the lock file, rebuild with the command for your
installation method.

For a standalone Home Manager flake:

``` shell
$ home-manager switch --flake .
```

For Home Manager as a NixOS module:

``` shell
$ sudo nixos-rebuild switch --flake .
```

For Home Manager as a nix-darwin module:

``` shell
$ darwin-rebuild switch --flake .
```

## Channel-Based Configurations {#sec-updating-channels}

Channels are mutable references outside the Home Manager configuration
itself. Updating a channel moves it to a newer revision of the same
channel or branch.

For a standalone Home Manager channel installation, update the user's
channels and then switch:

``` shell
$ nix-channel --update
…
unpacking channels...
$ home-manager switch
```

For Home Manager as a NixOS module, update the root user's Home Manager
channel and rebuild the system:

``` shell
$ sudo nix-channel --update home-manager
$ sudo nixos-rebuild switch
```

For Home Manager as a nix-darwin module, update the Home Manager channel
used by your nix-darwin configuration and rebuild the system:

``` shell
$ nix-channel --update home-manager
$ darwin-rebuild switch
```
