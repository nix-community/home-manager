{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.dircolors = {
      enable = true;
      terminalTypes = [ "xterm*" "ansi" ];

      settings = {
        OTHER_WRITABLE = "30;46";
        ".sh" = "01;32";
        ".csh" = "01;32";
      };

      extraConfig = ''
        # Extra dircolors configuration.
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.dir_colors \
        ${./settings-expected.conf}
    '';
  };
}
