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
    types
    literalExpression
    ;

  cfg = config.programs.fresh-editor;
  jsonFormat = pkgs.formats.json { };
  settingsFile =
    if cfg.mutableSettings then
      "config_${if pkgs.stdenv.hostPlatform.isDarwin then "macos" else "linux"}.json"
    else
      "config.json";
in
{
  meta.maintainers = with lib.maintainers; [ drupol ];
  options.programs.fresh-editor = {
    enable = mkEnableOption "fresh-editor";
    package = mkPackageOption pkgs "fresh-editor" { nullable = true; };
    mutableSettings = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to put declarative settings in Fresh's platform configuration
        file, leaving {file}`fresh/config.json` writable by Fresh. Declarative
        settings override the same keys in the user file. Project and session
        settings take precedence over the declarative settings.

        The declarative file is
        {file}`$XDG_CONFIG_HOME/fresh/config_linux.json` on Linux and
        {file}`~/.config/fresh/config_macos.json` on macOS. Fresh ignores
        {env}`XDG_CONFIG_HOME` on macOS.

        Before disabling this option while
        {option}`programs.fresh-editor.settings` is non-empty, remove or back up
        the Fresh-owned {file}`fresh/config.json`. Home Manager otherwise
        treats it as a file collision.
      '';
    };
    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.rust-analyzer ]";
      description = "Extra package to add to fresh";
    };
    defaultEditor = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to configure {command}`fresh` as the default
        editor using the {env}`EDITOR` and {env}`VISUAL`
        environment variables.
      '';
    };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        version = 1;
        theme = "dark";
        editor = {
          tab_size = 4;
          line_numbers = true;
        };
      };
      description = ''
        Configuration settings for fresh-editor. Find more configuration options in the user guide at:
        <https://getfresh.dev/docs/configuration/>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      if cfg.extraPackages != [ ] then
        [
          (pkgs.symlinkJoin {
            name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
            paths = [ cfg.package ];
            preferLocalBuild = true;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/fresh \
                --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
          })
        ]
      else
        [ cfg.package ];

    home.sessionVariables = mkIf cfg.defaultEditor {
      EDITOR = "fresh";
      VISUAL = "fresh";
    };

    xdg.configFile."fresh/${settingsFile}" = mkIf (cfg.settings != { }) {
      # Fresh uses ~/.config on macOS even when XDG_CONFIG_HOME is set.
      target = mkIf (
        cfg.mutableSettings && pkgs.stdenv.hostPlatform.isDarwin
      ) "${config.home.homeDirectory}/.config/fresh/${settingsFile}";
      source = jsonFormat.generate "config.json" cfg.settings;
    };
  };
}
