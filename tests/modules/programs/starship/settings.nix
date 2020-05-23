{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.starship = {
      enable = true;

      settings = mkMerge [
        {
          add_newline = false;
          prompt_order = [ "line_break" "package" "line_break" "character" ];
          scan_timeout = 10;
          character.symbol = "➜";
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

    nixpkgs.overlays = [
      (self: super: { starship = pkgs.writeScriptBin "dummy-starship" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        $home_files/.config/starship.toml \
        ${./settings-expected.toml}
    '';
  };
}
