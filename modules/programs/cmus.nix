{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.cmus;

in {
  meta.maintainers = [ hm.maintainers.joygnu ];

  options.programs.cmus = {
    enable = mkEnableOption "Enable cmus, the music player.";

    theme = mkOption {
      type = types.lines;
      default = "";
      example = "gruvbox";
      description = ''
        Select color theme. A list of available color themes can be found
        here: <https://github.com/cmus/cmus/tree/master/data>.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        set audio_backend = "mpd"
        set status_display = "default"
      '';
      description = "Extra configuration to add to cmus {file}`rc`.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.cmus ];

    home.file.".config/cmus/rc".text = ''
      ${optionalString (cfg.theme != "") "colorscheme ${cfg.theme}"}
      ${cfg.extraConfig}
    '';
  };
}
