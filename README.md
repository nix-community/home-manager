Home Manager using Nix
======================

This project provides a basic system for managing a user environment
using the [Nix][] package manager together with the Nix libraries
found in [Nixpkgs][]. It allows declarative configuration of user
specific (non global) packages and dotfiles.

Usage
-----

Before attempting to use Home Manager please read the warning below.

For a systematic overview of Home Manager and its available options,
please see

- the [Home Manager manual][manual],
- the [Home Manager configuration options][configuration options], and
- the 3rd party [Home Manager option search](https://mipmip.github.io/home-manager-option-search/).

If you would like to contribute to Home Manager
then please have a look at the [contributing][] chapter of the manual.

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

Home Manager targets [NixOS][] unstable and NixOS version 22.11 (the
current stable version), it may or may not work on other Linux
distributions and NixOS versions.

Also, the `home-manager` tool does not explicitly support rollbacks at
the moment so if your home directory gets messed up you'll have to fix
it yourself. See the [rollbacks][] section for instructions on how to
manually perform a rollback.

Now when your expectations have been built up and you are eager to try
all this out you can go ahead and read the rest of this text.

Contact
-------

You can chat with us on IRC in the channel [#home-manager][] on [OFTC][].
There is also a [Matrix room](https://matrix.to/#/#hm:rycee.net),
which is bridged to the IRC channel.

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

Home Manager provides both the channel-based setup and the flake-based one.
See [Nix Flakes][manual nix flakes] for a description of the flake-based setup.

Translations
------------

Home Manager has basic support for internationalization through
[gettext](https://www.gnu.org/software/gettext/). The translations are
hosted by [Weblate](https://weblate.org/). If you would like to
contribute to the translation effort then start by going to the
[Home Manager Weblate project](https://hosted.weblate.org/engage/home-manager/).

<a href="https://hosted.weblate.org/engage/home-manager/">
<img src="https://hosted.weblate.org/widgets/home-manager/-/multi-auto.svg" alt="Translation status" />
</a>

Releases
--------

Home Manager is developed against `nixpkgs-unstable` branch, which
often causes it to contain tweaks for changes/packages not yet
released in stable NixOS. To avoid breaking users' configurations,
Home Manager is released in branches corresponding to NixOS releases
(e.g. `release-22.11`). These branches get fixes, but usually not new
modules. If you need a module to be backported, then feel free to open
an issue.

License
-------

This project is licensed under the terms of the [MIT license](LICENSE).

[Nix]: https://nixos.org/explore.html
[NixOS]: https://nixos.org/
[Nixpkgs]: https://github.com/NixOS/nixpkgs
[manual]: https://nix-community.github.io/home-manager/index.html
[contributing]: https://nix-community.github.io/home-manager/#ch-contributing
[manual usage]: https://nix-community.github.io/home-manager/#ch-usage
[configuration options]: https://nix-community.github.io/home-manager/options.html
[#home-manager]: https://webchat.oftc.net/?channels=home-manager
[OFTC]: https://oftc.net/
[Nix Pills]: https://nixos.org/guides/nix-pills/
[Nix Flakes]: https://nixos.wiki/wiki/Flakes
[nix-darwin]: https://github.com/LnL7/nix-darwin
[manual standalone install]: https://nix-community.github.io/home-manager/index.html#sec-install-standalone
[manual nixos install]: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
[manual nix-darwin install]: https://nix-community.github.io/home-manager/index.html#sec-install-nix-darwin-module
[manual nix flakes]: https://nix-community.github.io/home-manager/index.html#ch-nix-flakes
[rollbacks]: https://nix-community.github.io/home-manager/index.html#sec-usage-rollbacks
