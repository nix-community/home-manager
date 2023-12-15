# How do I override the package used by a module? {#_how_do_i_override_the_package_used_by_a_module}

By default Home Manager will install the package provided by your chosen
`nixpkgs` channel but occasionally you might end up needing to change
this package. This can typically be done in two ways.

1.  If the module provides a `package` option, such as
    `programs.beets.package`, then this is the recommended way to
    perform the override. For example,

    ``` nix
    programs.beets.package = pkgs.beets.override { enableCheck = true; };
    ```

2.  If no `package` option is available then you can typically override
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
        (self: super: {
          skim = pkgsUnstable.skim;
        })
      ];

      # …
    }
    ```

    should work OK.
