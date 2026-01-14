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

  cfg = config.programs.aperture;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.aperture = {
    enable = mkEnableOption "aperture";
    package = mkPackageOption pkgs "aperture" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        listenaddr = "localhost:8081";
        staticroot = "./static";
        servestatic = false;
        debuglevel = "debug";
        autocert = false;
        servername = "aperture.example.com";
      };
      description = ''
        Configuration settings for aperture. All the available options can be found here:
        <https://github.com/lightninglabs/aperture/blob/master/sample-conf.yaml>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".aperture/aperture.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "aperture.yaml" cfg.settings;
    };
  };
}
