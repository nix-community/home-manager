# NixOS module {#sec-install-nixos-module}

Home Manager provides a NixOS module that allows you to prepare user
environments directly from the system configuration file, which often is
more convenient than using the `home-manager` tool. It also opens up
additional possibilities, for example, to automatically configure user
environments in NixOS declarative containers or on systems deployed
through NixOps.

To make the NixOS module available for use you must `import` it into
your system configuration. This is most conveniently done by adding a
Home Manager channel to the root user. For example, if you are following
Nixpkgs master or an unstable channel, you can run

``` shell
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
$ sudo nix-channel --update
```

and if you follow a Nixpkgs version 23.11 channel, you can run

``` shell
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager
$ sudo nix-channel --update
```

It is then possible to add

``` nix
imports = [ <home-manager/nixos> ];
```

to your system `configuration.nix` file, which will introduce a new
NixOS option called `home-manager.users` whose type is an attribute set
that maps user names to Home Manager configurations.

For example, a NixOS configuration may include the lines

``` nix
users.users.eve.isNormalUser = true;
home-manager.users.eve = { pkgs, ... }: {
  home.packages = [ pkgs.atool pkgs.httpie ];
  programs.bash.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "23.11";
};
```

and after a `sudo nixos-rebuild switch` the user eve's environment
should include a basic Bash configuration and the packages atool and
httpie.

:::{.note}
If `nixos-rebuild switch` does not result in the environment you expect,
you can take a look at the output of the Home Manager activation script
output using

``` shell
$ systemctl status "home-manager-$USER.service"
```
:::

If you do not plan on having Home Manager manage your shell
configuration then you must add either

``` bash
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

or

``` bash
. "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
```

to your shell configuration, depending on whether
[home-manager.useUserPackages](#nixos-opt-home-manager.useUserPackages) is enabled. This file can
be sourced directly by POSIX.2-like shells such as
[Bash](https://www.gnu.org/software/bash/) or [Z
shell](http://zsh.sourceforge.net/). [Fish](https://fishshell.com) users
can use utilities such as
[foreign-env](https://github.com/oh-my-fish/plugin-foreign-env) or
[babelfish](https://github.com/bouk/babelfish).

:::{.note}
By default packages will be installed to `$HOME/.nix-profile` but they
can be installed to `/etc/profiles` if

``` nix
home-manager.useUserPackages = true;
```

is added to the system configuration. This is necessary if, for example,
you wish to use `nixos-rebuild build-vm`. This option may become the
default value in the future.
:::

:::{.note}
By default, Home Manager uses a private `pkgs` instance that is
configured via the `home-manager.users.<name>.nixpkgs` options. To
instead use the global `pkgs` that is configured via the system level
`nixpkgs` options, set

``` nix
home-manager.useGlobalPkgs = true;
```

This saves an extra Nixpkgs evaluation, adds consistency, and removes
the dependency on `NIX_PATH`, which is otherwise used for importing
Nixpkgs.
:::

:::{.note}
Home Manager will pass `osConfig` as a module argument to any modules
you create. This contains the system's NixOS configuration.

``` nix
{ lib, pkgs, osConfig, ... }:
```
:::

Once installed you can see [Using Home Manager](#ch-usage) for a more detailed
description of Home Manager and how to use it.
