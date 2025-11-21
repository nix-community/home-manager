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

  cfg = config.programs.anvil-editor;
  tomlFormat = pkgs.formats.toml { };
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.anvil-editor = {
    enable = mkEnableOption "anvil-editor";
    package = mkPackageOption pkgs "anvil-editor" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        general.exec = [
          "aad"
          "ado"
        ];
        layout.column-tag = "New Cut Paste Snarf Zerox Delcol";
        typesetting.replace-cr-with-tofu = false;
        env = {
          FOO = "BAR";
          BAR = "FOO";
        };
      };
      description = ''
        Configuration settings for anvil-editor. All available options can be found here:
        <https://anvil-editor.net/reference/config/#settingstoml>.
      '';
    };
    style = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        TagFgColor = "#fefefe";
        TagBgColor = "#263859";
        BodyBgColor = "#17223b";
        ScrollFgColor = "#17223b";
        ScrollBgColor = "#6b778d";
        GutterWidth = 14;
        WinBorderColor = "#000000";
      };
      description = ''
        Style settings for anvil-editor. All available options can be found here:
        <https://anvil-editor.net/reference/config/#stylejs>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file = {
      ".anvil/settings.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "anvil-settings.toml" cfg.settings;
      };

      ".anvil/style.js" = mkIf (cfg.style != { }) {
        source = jsonFormat.generate "anvil-style.js" cfg.style;
      };
    };
  };
}
