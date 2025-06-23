{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cmus;
in
{
  meta.maintainers = [ lib.hm.maintainers.joygnu ];

  options.programs.cmus = {
    enable = lib.mkEnableOption "Enable cmus, the music player.";

    package = lib.mkPackageOption pkgs "cmus" { nullable = true; };

    theme = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "gruvbox";
      description = ''
        Select color theme. A list of available color themes can be found
        here: <https://github.com/cmus/cmus/tree/master/data>.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        set audio_backend = "mpd"
        set status_display = "default"
      '';
      description = "Extra configuration to add to cmus {file}`rc`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file.".config/cmus/rc".text = ''
      ${lib.optionalString (cfg.theme != "") "colorscheme ${cfg.theme}"}
      ${cfg.extraConfig}
    '';
  };
}
