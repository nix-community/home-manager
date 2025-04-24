{ config, pkgs, ... }:

let
  script = pkgs.writeShellScript "script.sh" ''
    echo "test"
  '';
in
{
  services.sxhkd = {
    enable = true;

    package = config.lib.test.mkStubPackage { outPath = "@sxhkd@"; };

    keybindings = {
      "super + a" = "run command a";
      "super + b" = null;
      "super + Shift + b" = "run command b";
      "super + s" = script;
    };

    extraConfig = ''
      super + c
        call command c

      # comment
      super + d
        call command d
    '';
  };

  nmt.script = ''
    sxhkdrc=home-files/.config/sxhkd/sxhkdrc

    assertFileExists $sxhkdrc

    assertFileContent $sxhkdrc ${
      pkgs.replaceVars ./sxhkdrc {
        inherit script;
      }
    }
  '';
}
