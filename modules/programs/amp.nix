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

  cfg = config.programs.amp;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.amp = {
    enable = mkEnableOption "amp";
    package = mkPackageOption pkgs "amp" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        theme = "solarized_dark";
        tab_width = 2;
        soft_tabs = true;
        line_wrapping = true;
        open_mode.exclusions = [
          "**/.git"
          "**/.svn"
        ];
        line_length_guide = [
          80
          100
        ];
      };
      description = ''
        Configuration settings for amp. All the details can be
        found here: <https://amp.rs/docs/configuration/>.
      '';
    };
  };

  config =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/amp"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/amp";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configPath}/config.yml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "amp-config.yml" cfg.settings;
      };
    };
}
