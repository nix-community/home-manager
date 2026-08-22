{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf optionals;
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
    ]
    ++ (optionals stdenv.hostPlatform.isDarwin [
      "`programs.prismlauncher.settings` is unsupported on Darwin."
    ]);

    warnings.expected = [
      ''
        The "not-a-theme" package in `programs.prismlauncher.themePackages`
        does not provide any Prism Launcher theme(s) and will be ignored.
      ''
    ];
  };
}
