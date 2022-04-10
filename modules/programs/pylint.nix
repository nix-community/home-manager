{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pylint;
  listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });
  iniFormat = pkgs.formats.ini { inherit listToValue; };
in {
  meta.maintainers = [ hm.maintainers.florpe ];
  options.programs.pylint = {
    enable = mkEnableOption "the pylint Python linter";
    package = mkOption {
      type = types.package;
      default = pkgs.python3Packages.pylint;
      defaultText = literalExpression "pkgs.python3Packages.pylint";
      description = "The pylint package to use.";
    };
    settings = mkOption {
      type = iniFormat.type;
      default = { };
      defaultText = literalExpression "{}";
      description = "The pylint configuration.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file.".pylintrc".source = iniFormat.generate "pylintrc" cfg.settings;
  };
}
