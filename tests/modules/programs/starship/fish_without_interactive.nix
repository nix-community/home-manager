{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      fish.enable = true;

      starship = {
        enable = true;
        enableInteractive = false;
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/fish/config.fish

      export GOT="$(tail -n 5 `_abs home-files/.config/fish/config.fish`)"
      export EXPECTED="
      if test \"\$TERM\" != dumb
          /home/hm-user/.nix-profile/bin/starship init fish | source

      end"

      export MESSAGE="
      ==========
       Expected
      ==========
      $EXPECTED
      ==========
         Got
      ==========
      $GOT
      ==========
      "

      if [[ "$GOT" != "$EXPECTED" ]]; then
        fail "$MESSAGE"
      fi
    '';
  };
}
