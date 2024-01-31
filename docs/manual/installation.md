# Installing Home Manager {#ch-installation}

Home Manager can be used in three primary ways:

1.  Using the standalone `home-manager` tool. For platforms other than
    NixOS and Darwin, this is the only available choice. It is also
    recommended for people on NixOS or Darwin that want to manage their
    home directory independently of the system as a whole. See
    [Standalone installation](#sec-install-standalone) for instructions
    on how to perform this installation.

2.  As a module within a NixOS system configuration. This allows the
    user profiles to be built together with the system when running
    `nixos-rebuild`. See [NixOS module](#sec-install-nixos-module) for a
    description of this setup.

3.  As a module within a
    [nix-darwin](https://github.com/LnL7/nix-darwin/) system
    configuration. This allows the user profiles to be built together
    with the system when running `darwin-rebuild`. See [nix-darwin
    module](#sec-install-nix-darwin-module) for a description of this
    setup.

:::{.note}
In this chapter we describe how to install Home Manager in the standard
way using channels. If you prefer to use [Nix
Flakes](https://nixos.wiki/wiki/Flakes) then please see the instructions
in [nix flakes](#ch-nix-flakes).
:::

```{=include=} sections
installation/standalone.md
installation/nixos.md
installation/nix-darwin.md
```
