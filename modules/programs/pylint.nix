{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pylint;

  # generators.toINI fails when it encounters a list, so we have to set up
  # some infrastructure.
  mkVal = generators.mkValueStringDefault { };
  mkINIVal = v:
    if isList v then
      builtins.concatStringsSep ", " (builtins.map mkVal v)
    else
      mkVal v;
  mkINIKeyVal = generators.mkKeyValueDefault { mkValueString = mkINIVal; } "=";
  mkINI = attrOfAttrs:
    generators.toINI { mkKeyValue = mkINIKeyVal; } attrOfAttrs;
  writeINI = name: attrsOfAttrs: pkgs.writeText name (mkINI attrsOfAttrs);

in {
  meta.maintainers = [ hm.maintainers.florpe ];
  options.programs.pylint = {
    enable = mkEnableOption "the pylint Python linter";
    package = mkOption {
      type = types.package;
      default = pkgs.python3Packages.pylint;
      defaultText = literalExpression "pkgs.python3Packages.pylint";
      description = "pylint package to use.";
    };
    settings = mkOption {
      type = types.attrs;
      default = { };
      defaultText = literalExpression "{}";
      description = "The pylint [BASIC] configuration to use.";
    };
    advanced = mkOption {
      type = types.attrsOf types.attrs;
      default = { };
      defaultText = literalExpression "{}";
      description =
        "The pylint configuration other than the [BASIC] section to use.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables =
      let pylintcfg = cfg.advanced // { BASIC = cfg.settings; };
      in { PYLINTRC = writeINI ".pylintrc" pylintcfg; };
  };
}
