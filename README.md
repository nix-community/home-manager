Home Manager using Nix
======================

This project provides a basic system for managing a user environment using the
[Nix][] package manager together with the Nix libraries found in [Nixpkgs][]. It
allows declarative configuration of user specific (non-global) packages and
dotfiles.

Usage
-----

Before attempting to use Home Manager please read [the warning
below](#words-of-warning).

For a systematic overview of Home Manager and its available options, please see:

- [Home Manager manual][manual]
- [Home Manager configuration options][configuration options]
- [3rd party Home Manager option
  search](https://mipmip.github.io/home-manager-option-search/)

If you would like to contribute to Home Manager, then please have a look at
["Contributing" in the manual][contributing].

Releases
--------

Home Manager is developed against `nixpkgs-unstable` branch, which often causes
it to contain tweaks for changes/packages not yet released in stable [NixOS][].
To avoid breaking users' configurations, Home Manager is released in branches
corresponding to NixOS releases (e.g. `release-23.11`). These branches get
fixes, but usually not new modules. If you need a module to be backported, then
feel free to open an issue.

Words of warning
----------------

Unfortunately, it is quite possible to get difficult to understand errors when
working with Home Manager. You should therefore be comfortable using the [Nix][]
language and the various tools in the Nix ecosystem.

If you are not very familiar with Nix but still want to use Home Manager then
you are strongly encouraged to start with a small and very simple configuration
and gradually make it more elaborate as you learn.

In some cases Home Manager cannot detect whether it will overwrite a previous
manual configuration. For example, the Gnome Terminal module will write to your
dconf store and cannot tell whether a configuration that it is about to be
overwritten was from a previous Home Manager generation or from manual
configuration.

Home Manager targets [NixOS][] unstable and NixOS version 23.11 (the current
stable version), it may or may not work on other Linux distributions and NixOS
versions.

Now when your expectations have been built up and you are eager to try all this
out you can go ahead and read the rest of this text.

Contact
-------

You can chat with us on IRC in the channel [#home-manager][] on [OFTC][]. There
is also a [Matrix room](https://matrix.to/#/#hm:rycee.net), which is bridged to
the IRC channel.

Installation
------------

Home Manager can be used in three primary ways:

1. Using the standalone `home-manager` tool. For platforms other than NixOS and
   Darwin, this is the only available choice. It is also recommended for people
   on [NixOS][] or Darwin that want to manage their home directory independently
   of the system as a whole. See ["Standalone installation" in the
   manual][manual standalone install] for instructions on how to perform this
   installation.

1. As a module within a NixOS system configuration. This allows the user
   profiles to be built together with the system when running `nixos-rebuild`.
   See ["NixOS module" in the manual][manual nixos install] for a description of
   this setup.

1. As a module within a [nix-darwin] system configuration. This allows the user
   profiles to be built together with the system when running `darwin-rebuild`.
   See ["nix-darwin module" in the manual][manual nix-darwin install] for a
   description of this setup.

Home Manager provides both the channel-based setup and the flake-based one. See
[Nix Flakes][manual nix flakes] for a description of the flake-based setup.

Translations
------------

Home Manager has basic support for internationalization through
[gettext](https://www.gnu.org/software/gettext/). The translations are hosted by
[Weblate](https://weblate.org/). If you would like to contribute to the
translation effort then start by going to the [Home Manager Weblate
project](https://hosted.weblate.org/engage/home-manager/).

<a href="https://hosted.weblate.org/engage/home-manager/">
    <img src="https://hosted.weblate.org/widgets/home-manager/-/multi-auto.svg" alt="Translation status" />
</a>

License
-------

This project is licensed under the terms of the [MIT license](LICENSE).

[#home-manager]: https://webchat.oftc.net/?channels=home-manager
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[NixOS]: https://nixos.org/
[Nix]: https://nixos.org/explore.html
[Nixpkgs]: https://github.com/NixOS/nixpkgs
[OFTC]: https://oftc.net/
[configuration options]: https://nix-community.github.io/home-manager/options.xhtml
[contributing]: https://nix-community.github.io/home-manager/#ch-contributing
[manual nix flakes]: https://nix-community.github.io/home-manager/#ch-nix-flakes
[manual nix-darwin install]: https://nix-community.github.io/home-manager/#sec-install-nix-darwin-module
[manual nixos install]: https://nix-community.github.io/home-manager/#sec-install-nixos-module
[manual standalone install]: https://nix-community.github.io/home-manager/#sec-install-standalone
[manual]: https://nix-community.github.io/home-manager/
[nix-darwin]: https://github.com/LnL7/nix-darwin
