{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.jjui;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [
    adda
    khaneliman
  ];

  options.programs.jjui = {
    enable = lib.mkEnableOption "jjui - A terminal user interface for jujutsu";

    package = lib.mkPackageOption pkgs "jjui" { nullable = true; };

    configDir = mkOption {
      type = lib.types.str;
      default =
        let
          dir = if pkgs.stdenv.isDarwin then "Library/Application Support" else config.xdg.configHome;
        in
        "${dir}/jjui";
      defaultText = lib.literalExpression "Darwin: \"Library/Application Support/jjui\" \nLinux: \${config.xdg.configHome}/jjui";
      example = lib.literalExpression "\${config.home.homeDirectory}/.jjui";
      description = ''
        The directory to contain jjui configuration files.
      '';
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        revisions = {
          template = "builtin_log_compact";
          revset = "";
        };
      };
      description = ''
        Options to add to the {file}`config.toml` file. See
        <https://github.com/idursun/jjui/wiki/Configuration>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      file."${cfg.configDir}/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "jjui-config" cfg.settings;
      };

      sessionVariables = {
        JJUI_CONFIG_DIR = cfg.configDir;
      };
    };
  };
}
