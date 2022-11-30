{ config, lib, pkgs, ... }:
with builtins // lib;
let
  cfg = config.programs.python.pylint;
  listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });
  iniFormat = pkgs.format.ini { inherit listToValue; };
in {
  imports = [
    (mkRenamedOptionModule [ "programs" "pylint" ] [
      "programs"
      "python"
      "pylint"
    ])
  ];
  options.programs.python.pylint = {
    enable = mkEnableOption "the pylint Python linter";
    package =
      mkPackageOption config.programs.python.pythonPackages "pylint" { };
    settings = mkOption {
      type = types.nullOr iniFormat.type;
      description = ''
        Configuration written to <code>.pylintrc</code>.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        {
          "tool.pylint.main".fail-under = 10;
        }
      '';
    };
  };
  config = mkIf cfg.enable {
    programs.python.packages = (_: [ cfg.package ]);
    home.file.".pylintrc" = mkIf (cfg.settings != null) {
      source = iniFormat.generate "pylint-config" cfg.settings;
    };
  };
  meta.maintainers = with maintainers; [ anselmschueler ];
}
