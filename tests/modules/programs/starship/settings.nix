{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.starship = {
      enable = true;

      settings = mkMerge [
        {
          add_newline = false;
          format = concatStrings [
            "$line_break"
            "$package"
            "$line_break"
            "$character"
          ];
          scan_timeout = 10;
          character = {
            success_symbol = "➜";
            error_symbol = "➜";
          };
          package.disabled = true;
          memory_usage.threshold = -1;
          aws.style = "bold blue";
          battery = {
            charging_symbol = "⚡️";
            display = [{
              threshold = 10;
              style = "bold red";
            }];
          };
        }

        {
          aws.disabled = true;

          battery.display = [{
            threshold = 30;
            style = "bold yellow";
          }];
        }
      ];
    };

    test.stubs.starship = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/starship.toml \
        ${./settings-expected.toml}
    '';
  };
}
