Home Manager using Nix
======================

This project provides a basic system for managing a user environment
using the [Nix][] package manager together with the Nix libraries
found in [Nixpkgs][]. It allows declarative configuration of user
specific (non global) packages and dotfiles.

Before attempting to use Home Manager please read the warning below.

For a more systematic overview of Home Manager and its available
options, please see the [Home Manager manual][manual].

Words of warning
----------------

Unfortunately, it is quite possible to get difficult to understand
errors when working with Home Manager, such as infinite loops with no
clear source reference. You should therefore be comfortable using the
Nix language and the various tools in the Nix ecosystem. Reading
through the [Nix Pills][] document is a good way to familiarize
yourself with them.

If you are not very familiar with Nix but still want to use Home
Manager then you are strongly encouraged to start with a small and
very simple configuration and gradually make it more elaborate as you
learn.

In some cases Home Manager cannot detect whether it will overwrite a
previous manual configuration. For example, the Gnome Terminal module
will write to your dconf store and cannot tell whether a configuration
that it is about to be overwritten was from a previous Home Manager
generation or from manual configuration.

Home Manager targets [NixOS][] unstable and NixOS version 21.05 (the
current stable version), it may or may not work on other Linux
distributions and NixOS versions.

Also, the `home-manager` tool does not explicitly support rollbacks at
the moment so if your home directory gets messed up you'll have to fix
it yourself. See the [rollbacks](#rollbacks) section for instructions
on how to manually perform a rollback.

Now when your expectations have been built up and you are eager to try
all this out you can go ahead and read the rest of this text.

Contact
-------

You can chat with us on IRC in the channel [#home-manager][] on
[OFTC][].

Installation
------------

Currently the easiest way to install Home Manager is as follows:

1.  Make sure you have a working Nix installation. Specifically, make
    sure that your user is able to build and install Nix packages. For
    example, you should be able to successfully run a command like
    `nix-instantiate '<nixpkgs>' -A hello` without having to switch to
    the root user. For a multi-user install of Nix this means that
    your user must be covered by the
    [`allowed-users`][nixAllowedUsers] Nix option. On NixOS you can
    control this option using the
    [`nix.allowedUsers`][nixosAllowedUsers] system option.

    Note that Nix 2.4 (`nixUnstable`) is not yet supported.

2.  Add the appropriate Home Manager channel. If you are following
    Nixpkgs master or an unstable channel you can run

    ```shell
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    ```

    and if you follow a Nixpkgs version 21.05 channel you can run

    ```shell
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz home-manager
    nix-channel --update
    ```

    On NixOS you may need to log out and back in for the channel to
    become available. On non-NixOS you may have to add

    ```shell
    export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
    ```

    to your shell (see [nix#2033](https://github.com/NixOS/nix/issues/2033)).

3.  Install Home Manager and create the first Home Manager generation:

    ```shell
    nix-shell '<home-manager>' -A install
    ```

    Once finished, Home Manager should be active and available in your
    user environment.

3.  If you do not plan on having Home Manager manage your shell
    configuration then you must source the

    ```shell
    $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
    ```

    file in your shell configuration. This file can be sourced
    directly by POSIX.2-like shells such as [Bash][] or [Z shell][].
    [Fish][] users can use utilities such as [foreign-env][] or
    [babelfish][].

    For example, if you use Bash then add

    ```bash
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    ```

    or this when managing home configuration together with system
    configuration

    ```bash
    . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
    ```

    to your `~/.profile` file.

If instead of using channels you want to run Home Manager from a Git
checkout of the repository then you can use the
`programs.home-manager.path` option to specify the absolute path to
the repository.

Once installed you can now read the [usage section][manual usage] of the manual.

Nix Flakes
----------

Home Manager includes a `flake.nix` file for compatibility with [Nix Flakes][]
for those that wish to use it as a module. A bare-minimum `flake.nix` would be
as follows:

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { home-manager, nixpkgs, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jdoe = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}
```

If you are not using NixOS you can place the following flake in
`~/.config/nixpkgs/flake.nix` to load your standard Home Manager
configuration:

```nix
{
  description = "A Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    homeConfigurations = {
      jdoe = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/jdoe";
        username = "jdoe";
        configuration.imports = [ ./home.nix ];
      };
    };
  };
}
```

Note, the Home Manager library is exported by the flake under
`lib.hm`.

When using flakes, switch to new configurations as you do for the
whole system (e. g. `nixos-rebuild switch --flake <path>`) instead of
using the `home-manager` command line tool.

Releases
--------

Home Manager is developed against `nixpkgs-unstable` branch, which
often causes it to contain tweaks for changes/packages not yet
released in stable NixOS. To avoid breaking users' configurations,
Home Manager is released in branches corresponding to NixOS releases
(e.g. `release-21.05`). These branches get fixes, but usually not new
modules. If you need a module to be backported, then feel free to open
an issue.

License
-------

This project is licensed under the terms of the [MIT license](LICENSE).

[Bash]: https://www.gnu.org/software/bash/
[Nix]: https://nixos.org/nix/
[NixOS]: https://nixos.org/
[Nixpkgs]: https://nixos.org/nixpkgs/
[nixAllowedUsers]: https://nixos.org/nix/manual/#conf-allowed-users
[nixosAllowedUsers]: https://nixos.org/nixos/manual/options.html#opt-nix.allowedUsers
[Z shell]: http://zsh.sourceforge.net/
[manual]: https://nix-community.github.io/home-manager/
[manual usage]: https://nix-community.github.io/home-manager/#ch-usage
[configuration options]: https://nix-community.github.io/home-manager/options.html
[#home-manager]: https://webchat.oftc.net/?channels=home-manager
[OFTC]: https://oftc.net/
[samueldr]: https://github.com/samueldr/
[Nix Pills]: https://nixos.org/nixos/nix-pills/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[Fish]: https://fishshell.com
[foreign-env]: https://github.com/oh-my-fish/plugin-foreign-env
[babelfish]: https://github.com/bouk/babelfish
