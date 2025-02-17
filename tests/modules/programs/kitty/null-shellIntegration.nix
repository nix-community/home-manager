{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kitty = {
      enable = true;

      shellIntegration.mode = null;
    };

    test.stubs.kitty = { };

    nmt.script = ''
      assertFileExists home-files/.config/kitty/kitty.conf
      assertFileContent \
        home-files/.config/kitty/kitty.conf \
        ${./null-shellIntegration-expected.conf}
    '';
  };
}
