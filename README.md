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

Home Manager targets [NixOS][] unstable and NixOS version 21.11 (the
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

Home Manager can be used in three primary ways:

1. Using the standalone `home-manager` tool. For platforms other than
   NixOS and Darwin, this is the only available choice. It is also
   recommended for people on NixOS or Darwin that want to manage their
   home directory independently of the system as a whole. See
   [Standalone installation][manual standalone install] in the manual
   for instructions on how to perform this installation.

2. As a module within a NixOS system configuration. This allows the
   user profiles to be built together with the system when running
   `nixos-rebuild`. See [NixOS module installation][manual nixos
   install] in the manual for a description of this setup.

3. As a module within a [nix-darwin][] system configuration. This
   allows the user profiles to be built together with the system when
   running `darwin-rebuild`. See [nix-darwin module
   installation][manual nix-darwin install] in the manual for a
   description of this setup.

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
(e.g. `release-21.11`). These branches get fixes, but usually not new
modules. If you need a module to be backported, then feel free to open
an issue.

License
-------

This project is licensed under the terms of the [MIT license](LICENSE).

[Nix]: https://nixos.org/nix/
[NixOS]: https://nixos.org/
[Nixpkgs]: https://nixos.org/nixpkgs/
[manual]: https://nix-community.github.io/home-manager/
[manual usage]: https://nix-community.github.io/home-manager/#ch-usage
[configuration options]: https://nix-community.github.io/home-manager/options.html
[#home-manager]: https://webchat.oftc.net/?channels=home-manager
[OFTC]: https://oftc.net/
[Nix Pills]: https://nixos.org/nixos/nix-pills/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[nix-darwin]: https://github.com/LnL7/nix-darwin/
[manual standalone install]: https://nix-community.github.io/home-manager/index.html#sec-install-standalone
[manual nixos install]: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
[manual nix-darwin install]: https://nix-community.github.io/home-manager/index.html#sec-install-nix-darwin-module
