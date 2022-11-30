{ config, pkgs, lib, ... }:
with builtins // lib;
let
  cfg = config.programs.python.mypy;
  iniFormat = pkgs.formats.ini { };
in {
  options.programs.python.mypy = {
    enable = mkEnableOption "mypy";
    package = mkPackageOption pkgs "mypy" { };
    settings = mkOption {
      type = types.nullOr iniFormat.type;
      description = ''
        Configuration written to <code>$XDG_CONFIG_HOME/mypy/config</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          mypy.strict = true;
        }
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = mkIf cfg.enable [ cfg.package ];
    xdg.configFile."mypy/config" = mkIf (cfg.settings != null) {
      source = iniFormat.generate "mypy-config" cfg.settings;
    };
  };
}
