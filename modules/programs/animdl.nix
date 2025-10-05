{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.animdl;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.animdl = {
    enable = mkEnableOption "animdl";
    package = mkPackageOption pkgs "animdl" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        default_provider = "animixplay";
        site_urls.animixplay = "https://www.animixplay.to/";
        quality_string = "best[subtitle]/best";
        default_player = "mpv";
        ffmpeg = {
          executable = "ffmpeg";
          hls_download = false;
          submerge = true;
        };
      };
      description = ''
        Configuration settings for animdl. All the available options can be found here:
        <https://github.com/justfoolingaround/animdl?tab=readme-ov-file#configurations>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.animdl" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".config/animdl/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "animdl.yml" cfg.settings;
    };
  };
}
