{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.cmus;
in {
  meta.maintainers = [ joygnu ];

  options = {
    programs.cmus = {
      enable = mkEnableOption "Enable cmus, the music player.";

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set audio_backend = "mpd"
          set status_display = "default"
        '';
        description = "Extra configuration to add to cmus rc.";
      };

      theme = mkOption {
        type = types.lines;
        default = "";
        example = "gruvbox";
        description =
          "Select color theme; list of available color themes can be found here: https://github.com/cmus/cmus/tree/master/data.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.cmus ];

    home.file.".config/cmus/rc".text = ''
      colorscheme ${cfg.theme}
      ${cfg.extraConfig}
    '';
  };
}
