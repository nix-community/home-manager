# How do I change the package used by a module? {#_how_do_i_change_the_package_used_by_a_module}

By default Home Manager will install the package provided by your chosen
`nixpkgs` channel but occasionally you might end up needing to change
this package. This can typically be done in two ways.

1.  If the module provides a `package` option, such as
    `programs.beets.package`, then this is the recommended way to
    perform the change. For example,

    ``` nix
    programs.beets.package = pkgs.beets.override { pluginOverrides = { beatport.enable = false; }; };
    ```

    See [Nix pill 17](https://nixos.org/guides/nix-pills/nixpkgs-overriding-packages.html)
    for more information on package overrides. Alternatively, if you want
    to use the `beets` package from Nixpkgs unstable, then a configuration like

    ``` nix
    { pkgs, config, ... }:

    let
      pkgsUnstable = import <nixpkgs-unstable> {};
    in
    {
      programs.beets.package = pkgsUnstable.beets;

      # …
    }
    ```

    should work OK. With flakes, pass the unstable package set as
    described in
    [How do I install packages from Nixpkgs unstable?](#_how_do_i_install_packages_from_nixpkgs_unstable)
    and then use the extra module argument:

    ``` nix
    { pkgsUnstable, ... }:

    {
      programs.beets.package = pkgsUnstable.beets;

      # …
    }
    ```

2.  If no `package` option is available then you can typically change
    the relevant package using an
    [overlay](https://nixos.org/nixpkgs/manual/#chap-overlays).

    For example, if you want to use the `programs.skim` module but use
    the `skim` package from Nixpkgs unstable, then a configuration like

    ``` nix
    { pkgs, config, ... }:

    let
      pkgsUnstable = import <nixpkgs-unstable> {};
    in

    {
      programs.skim.enable = true;

      nixpkgs.overlays = [
        (_final: _prev: {
          skim = pkgsUnstable.skim;
        })
      ];

      # …
    }
    ```

    should work OK.

    The same Home Manager overlay works in a flake-based standalone
    configuration if `pkgsUnstable` is passed to the Home Manager
    module:

    ``` nix
    { pkgsUnstable, ... }:

    {
      programs.skim.enable = true;

      nixpkgs.overlays = [
        (_final: _prev: {
          skim = pkgsUnstable.skim;
        })
      ];

      # …
    }
    ```

    This also works when Home Manager is used as a NixOS or nix-darwin
    module without `home-manager.useGlobalPkgs = true`. If
    `home-manager.useGlobalPkgs = true` is enabled, Home Manager uses
    the system package set and the `nixpkgs.*` options inside Home
    Manager are disabled. In that case, put the overlay in the system
    configuration instead, for example:

    ``` nix
    { pkgsUnstable, ... }:

    {
      nixpkgs.overlays = [
        (_final: _prev: {
          skim = pkgsUnstable.skim;
        })
      ];
    }
    ```

    In a flake-based NixOS or nix-darwin configuration, pass
    `pkgsUnstable` to `nixosSystem` or `darwinSystem` with
    `specialArgs`.
