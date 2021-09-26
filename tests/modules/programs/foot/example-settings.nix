{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.foot = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        main = {
          term = "xterm-256color";

          font = "Fira Code:size=11";
          dpi-aware = "yes";
        };

        mouse = { hide-when-typing = "yes"; };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/foot/foot.ini \
        ${./example-settings-expected.ini}
    '';
  };
}
