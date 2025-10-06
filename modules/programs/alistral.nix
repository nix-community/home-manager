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

  cfg = config.programs.alistral;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.alistral = {
    enable = mkEnableOption "alistral";
    package = mkPackageOption pkgs "alistral" { nullable = true; };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        default_user = "spanish_inquisition";
        listenbrainz_url = "https://api.listenbrainz.org/1/";
        musicbrainz_url = "http://musicbrainz.org/ws/2";
      };
      description = ''
        Configuration settings for alistral. You can see the details here:
        <https://rustynova016.github.io/Alistral/config/config.html>.
      '';
    };
  };

  config =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/alistral"
        else
          ".config/alistral";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configDir}/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "alistral-config.json" cfg.settings;
      };
    };
}
