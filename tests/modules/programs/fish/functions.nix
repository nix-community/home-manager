{ config, lib, pkgs, ... }:

with lib;

let

  func = pkgs.writeText "func.fish" ''
    function func
      echo "Hello"
    end
  '';

  funcEvent = pkgs.writeText "func-event.fish" ''
    function func-event --on-event="fish_command_not_found"
      echo "Not found!"
    end
  '';

in {
  config = {
    programs.fish = {
      enable = true;

      functions = {
        func = ''echo "Hello"'';
        func-event = {
          body = ''echo "Not found!"'';
          onEvent = "fish_command_not_found";
        };
      };
    };

    nmt = {
      description =
        "if fish.function is set, check file exists and contents match";
      script = ''
        assertFileExists $home_files/.config/fish/functions/func.fish
        echo ${func}
        assertFileContent $home_files/.config/fish/functions/func.fish ${func}

        assertFileExists $home_files/.config/fish/functions/func-event.fish
        echo ${funcEvent}
        assertFileContent $home_files/.config/fish/functions/func-event.fish ${funcEvent}
      '';

    };
  };
}
