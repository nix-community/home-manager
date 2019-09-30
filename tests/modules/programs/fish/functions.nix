{ config, lib, pkgs, ... }:

with lib;

let

  func = pkgs.writeText "func.fish" ''
    function func
      echo "Hello"
    end
  '';

in {
  config = {
    programs.fish = {
      enable = true;

      functions = { func = ''echo "Hello"''; };
    };

    nmt = {
      description =
        "if fish.function is set, check file exists and contents match";
      script = ''
        assertFileExists home-files/.config/fish/functions/func.fish
        echo ${func}
        assertFileContent home-files/.config/fish/functions/func.fish ${func}
      '';

    };
  };
}
