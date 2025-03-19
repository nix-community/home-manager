{ pkgs, config, lib, ... }:

let

  inherit (lib) mkEnableOption mkPackageOption mkOption literalExpression;

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.tex-fmt;

in {
  meta.maintainers = with lib.maintainers; [ mirkolenz wgunderwood ];

  options.programs.tex-fmt = {
    enable = mkEnableOption "tex-fmt";

    package = mkPackageOption pkgs "tex-fmt" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          wrap = true;
          tabsize = 2;
          tabchar = "space";
          lists = [];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/tex-fmt/tex-fmt.toml` on Linux or
        {file}`$HOME/Library/Application Support/tex-fmt/tex-fmt.toml` on Darwin.
        See <https://github.com/WGUNDERWOOD/tex-fmt> and
        <https://github.com/WGUNDERWOOD/tex-fmt/blob/master/tex-fmt.toml>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/tex-fmt/tex-fmt.toml" =
      lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "tex-fmt-config" cfg.settings;
      };
  };
}
