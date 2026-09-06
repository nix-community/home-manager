{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf optional;
  inherit (pkgs) stdenv;
in

{
  programs.prismlauncher = {
    enable = true;

    settings = mkIf stdenv.hostPlatform.isDarwin {
      foo = "bar";
    };

    themes = {
      foo = ./asserts.nix;
      baz = {
        theme = { };
        style = ./asserts.nix;
      };
    };

    themePackages = [ (config.lib.test.mkStubPackage { name = "not-a-theme"; }) ];
  };

  test.asserts = {
    assertions.expected = [
      "`programs.prismlauncher.themes.baz.theme` must not be empty."
      "`programs.prismlauncher.themes.foo` must be a directory when set to a path."
    ];

    warnings.expected = optional stdenv.hostPlatform.isDarwin ''
      The option `programs.prismlauncher.settings` is currently bugged on Darwin.

      See the related issue:
        https://github.com/nix-community/home-manager/issues/9916
    '';
  };
}
