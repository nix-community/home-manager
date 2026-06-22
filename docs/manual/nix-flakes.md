# Nix Flakes {#ch-nix-flakes}

Home Manager is compatible with [Nix
Flakes](https://wiki.nixos.org/wiki/Flakes). But please be aware that this
support is still experimental and may change in backwards
incompatible ways.

Just like in the standard installation you can use the Home Manager
flake in three ways:

1.  Using the standalone `home-manager` tool. For platforms other than
    NixOS and Darwin, this is the only available choice. It is also
    recommended for people on NixOS or Darwin that want to manage their
    home directory independently of the system as a whole. See
    [Standalone setup](#sec-flakes-standalone) for instructions on how
    to perform this installation.

2.  As a module within a NixOS system configuration. This allows the
    user profiles to be built together with the system when running
    `nixos-rebuild`. See [NixOS module](#sec-flakes-nixos-module) for a
    description of this setup.

3.  As a module within a [nix-darwin](https://github.com/nix-darwin/nix-darwin/)
    system configuration. This allows the user profiles to be built
    together with the system when running `darwin-rebuild`. See
    [nix-darwin module](#sec-flakes-nix-darwin-module) for a
    description of this setup.

Advanced users may want Home Manager's `nixpkgs` input to follow the
same Nixpkgs input as the rest of their flake. This avoids a second
Nixpkgs input and makes Home Manager use the same pinned Nixpkgs source
revision as the rest of the configuration:

``` nix
home-manager.inputs.nixpkgs.follows = "nixpkgs";
```

This removes the compatibility assumption between Home Manager and the
Nixpkgs revision in Home Manager's own lock file, so use it carefully,
especially when tracking unstable branches.

This does not by itself make Home Manager use the same `pkgs` value as
your NixOS or nix-darwin system. In NixOS and nix-darwin module setups,
`home-manager.useGlobalPkgs = true` controls that behavior by making
Home Manager modules receive the system `pkgs` value. When
`home-manager.useGlobalPkgs` is enabled, configure Nixpkgs overlays and
configuration at the system level instead of through Home Manager
`nixpkgs.*` options.

```{=include=} sections
nix-flakes/prerequisites.md
nix-flakes/standalone.md
nix-flakes/nixos.md
nix-flakes/nix-darwin.md
nix-flakes/flake-parts.md
```
