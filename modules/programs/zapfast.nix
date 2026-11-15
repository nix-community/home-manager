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

  jsonFormat = pkgs.formats.json { };
  cfg = config.programs.zapfast;
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/me.paolino.zapfast/settings.json"
    else
      "${config.xdg.configHome}/zapfast/settings.json";
in
{
  meta.maintainers = [ lib.maintainers.cleboost ];

  options.programs.zapfast = {
    enable = mkEnableOption "zapfast";

    package = mkPackageOption pkgs "zapfast" { nullable = true; };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "dark";
          notifications = true;
          message_sound = "none";
          mention_sound = "none";
        }
      '';
      description = ''
        Configuration settings for ZapFast, merged into
        {file}`$XDG_CONFIG_HOME/zapfast/settings.json` on Linux or
        {file}`~/Library/Application Support/me.paolino.zapfast/settings.json`
        on Darwin.

        Values declared here take precedence on Home Manager activation, while
        other keys saved by ZapFast are preserved.
        See <https://zapfast.rocks/settings-and-files/> for available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.activation.zapfastSettings = mkIf (cfg.settings != { }) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = settingsPath;
          staticSettings = jsonFormat.generate "zapfast-settings.json" cfg.settings;
        }
      )
    );
  };
}
