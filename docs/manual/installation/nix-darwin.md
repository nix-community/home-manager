# nix-darwin module {#sec-install-nix-darwin-module}

Home Manager provides a module that allows you to prepare user
environments directly from the
[nix-darwin](https://github.com/LnL7/nix-darwin/) configuration file,
which often is more convenient than using the `home-manager` tool.

To make the NixOS module available for use you must `import` it into
your system configuration. This is most conveniently done by adding a
Home Manager channel. For example, if you are following Nixpkgs master
or an unstable channel, you can run

``` shell
$ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
$ nix-channel --update
```

and if you follow a Nixpkgs version 23.11 channel, you can run

``` shell
$ nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager
$ nix-channel --update
```

It is then possible to add

``` nix
imports = [ <home-manager/nix-darwin> ];
```

to your nix-darwin `configuration.nix` file, which will introduce a new
NixOS option called `home-manager` whose type is an attribute set that
maps user names to Home Manager configurations.

For example, a nix-darwin configuration may include the lines

``` nix
users.users.eve = {
  name = "eve";
  home = "/Users/eve";
};
home-manager.users.eve = { pkgs, ... }: {
  home.packages = [ pkgs.atool pkgs.httpie ];
  programs.bash.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "23.11";
};
```

and after a `darwin-rebuild switch` the user eve's environment should
include a basic Bash configuration and the packages atool and httpie.

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
[home-manager.useUserPackages](#nix-darwin-opt-home-manager.useUserPackages) is enabled. This
file can be sourced directly by POSIX.2-like shells such as
[Bash](https://www.gnu.org/software/bash/) or [Z
shell](http://zsh.sourceforge.net/). [Fish](https://fishshell.com) users
can use utilities such as
[foreign-env](https://github.com/oh-my-fish/plugin-foreign-env) or
[babelfish](https://github.com/bouk/babelfish).

:::{.note}
By default user packages will not be ignored in favor of
`environment.systemPackages`, but they will be installed to
`/etc/profiles/per-user/$USERNAME` if

``` nix
home-manager.useUserPackages = true;
```

is added to the nix-darwin configuration. This option may become the
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
you create. This contains the system's nix-darwin configuration.

``` nix
{ lib, pkgs, osConfig, ... }:
```
:::

Once installed you can see [Using Home Manager](#ch-usage) for a more detailed
description of Home Manager and how to use it.
