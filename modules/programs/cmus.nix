{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.cmus;

in {
  meta.maintainers = [ maintainers.joygnu ];

  options = {
    programs.cmus = {
      enable = mkEnableOption "Enable cmus, the music player.";

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description =
          "Extra configuration values to be appended to the cmus config file.";
      };

      theme = {
        name = mkOption {
          type = types.str;
          default = "";
          description = "Name of the theme to create (e.g., gruvbox).";
        };

        content = mkOption {
          type = types.lines;
          default = "";
          description =
            "Plain text for the theme. It will be written to <theme.name>.theme.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.cmus ];

    home.file.".config/cmus/rc".text = ''
      ${cfg.extraConfig}
    '';

    home.file.".config/cmus/${cfg.theme.name}.theme".text = ''
      ${cfg.theme.content}
    '';
  };
}

