{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.readline = {
      enable = true;

      bindings = {
        "\\C-h" = "backward-kill-word";
        "Control-p" = ''"whups"'';
      };

      variables = {
        bell-style = "audible";
        completion-map-case = true;
        completion-prefix-display-length = 2;
      };

      extraConfig = ''
        $if mode=emacs
        "\e[1~": beginning-of-line
        $endif
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.inputrc \
        ${./using-all-options.txt}
    '';
  };
}
