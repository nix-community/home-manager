{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.python;
in {
  options.programs.python = {
    versionName = mkOption {
      type = with types; nullOr str;
      apply = opt:
        if opt != null then replaceStrings [ "." ] [ "" ] opt else null;
      description = ''
        The Python version to use.
        Setting this value automatically sets <code>programs.python.pythonPackages</code>.
        The value is automatically stripped of periods to match the nixpkgs naming convention.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''"311"'';
    };
    pythonPackages = mkOption {
      type = types.raw;
      description = "The Python package set to use.";
      default = if cfg.versionName != null then
        pkgs."python${cfg.versionName}Packages"
      else
        pkgs.python3Packages;
      defaultText = literalExpression "pkgs.python3Packages";
      example = literalExpression "pkgs.python311Packages";
    };
    enable = mkEnableOption "the Python interpreter";
    package = mkPackageOption cfg.pythonPackages "Python interpreter" {
      default = [ "python" ];
    } // {
      apply = pkg:
        if pkg ? withPackages then
          pkg.withPackages cfg.packages
        else
          trace ''
            You have provided a package as programs.python.package that doesn't have the withPackages function.
            This disables specifying packages via programs.python.packages unless you manually install them.
          '';
    };
    packages = mkOption {
      type = with types; functionTo (listOf package);
      apply = x: if !isFunction x then _: x else x;
      description = ''
        The Python packages to install for the Python interpreter.
      '';
      default = pkgs: [ ];
      defaultText = literalExpression "pkgs: [ ]";
      example = literalExpression "pkgs: [ pkgs.requests ]";
    };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
