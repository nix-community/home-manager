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

and if you follow a Nixpkgs version 26.05 channel, you can run

``` shell
$ sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
$ sudo nix-channel --update
```

It is then possible to add

``` nix
imports = [ <home-manager/nixos> ];
```

to your system `configuration.nix` file, which will introduce a new
NixOS option called `home-manager.users` whose type is an attribute set
that maps user names to Home Manager configurations.

Alternatively, home-manager installation can be done declaratively through configuration.nix using the following syntax:
```nix
{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz;
in
{
  imports =
    [
      (import "${home-manager}/nixos")
    ];

  users.users.eve.isNormalUser = true;
  home-manager.users.eve = { pkgs, ... }: {
    home.packages = [ pkgs.atool pkgs.httpie ];
    programs.bash.enable = true;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "26.05";
  };
}
```

For example, a NixOS configuration may include the lines

``` nix
users.users.eve.isNormalUser = true;
home-manager.users.eve = { pkgs, ... }: {
  home.packages = [ pkgs.atool pkgs.httpie ];
  programs.bash.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

};
```

and after a `sudo nixos-rebuild switch` the user eve's environment
should include a basic Bash configuration and the packages atool and
httpie.

:::{.note}
If `nixos-rebuild switch` does not result in the environment you expect,
then the service to inspect depends on the activation mode.

By default, Home Manager activates each configured user during boot and
system rebuilds through a NixOS system service:

``` shell
$ systemctl status "home-manager-$USER.service"
```

If `home-manager.startAsUserService = true` is set, Home Manager instead
activates through the user's systemd service:

``` shell
$ systemctl --user status home-manager.service
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
Home Manager passes extra module arguments to each
`home-manager.users.<name>` module:

``` nix
{ lib, pkgs, osConfig, nixosConfig, osClass, modulesPath, ... }:
```

Here `osConfig` contains the system's NixOS configuration and `nixosConfig`
is a NixOS-specific alias for the same value. The `lib` argument is Home
Manager's extended library. You can pass additional module arguments with
`home-manager.extraSpecialArgs`.
:::

:::{.note}
Use `home-manager.sharedModules` to add Home Manager modules to every user
declared under `home-manager.users`.
:::

Once installed you can see [Using Home Manager](../usage.md#ch-usage) for a more detailed
description of Home Manager and how to use it.
