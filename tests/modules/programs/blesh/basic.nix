{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.blesh = {
      enable = true;
      options = {
        prompt_ps1_transient = "trim:same-dir";
        prompt_ruler = "empty-line";
      };
      faces = { auto_complete = "fg=240"; };
      imports = [ "contrib/bash-preexec" ];
      blercExtra = ''
        function my/complete-load-hook {
          bleopt complete_auto_history=
          bleopt complete_ambiguous=
          bleopt complete_menu_maxlines=10
        };
        blehook/eval-after-load complete my/complete-load-hook
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.blerc \
        ${./blerc-basic}
    '';
  };
}
