{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ptyxis-basic-palette = ./palette.nix;
  ptyxis-empty-default-palette = {
    programs.ptyxis = {
      enable = true;
      defaultPalette = "";
    };

    test.asserts.assertions.expected = [
      "programs.ptyxis.defaultPalette must not be an empty string."
    ];
  };
}
