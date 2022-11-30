{ config, pkgs, lib, ... }:
with builtins // lib;
let
  cfg = config.programs.python.pip;
  iniFormat = pkgs.formats.ini { };
in {
  options.programs.python.pip = {
    enable = mkEnableOption "pip";
    package = mkPackageOption config.programs.python.pythonPackages "pip" { };
    settings = mkOption {
      type = types.nullOr iniFormat.type;
      description = ''
        Configuration written to <code>$XDG_CONFIG_HOME/pip/pip.conf</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          global.timeout = 60;
        }
      '';
    };
  };
  config = mkIf cfg.enable {
    programs.python.packages = (_: [ cfg.package ]);
    xdg.configFile."pip/pip.conf" = mkIf (cfg.settings != null) {
      source = iniFormat.generate "pip-config" cfg.settings;
    };
  };
}
