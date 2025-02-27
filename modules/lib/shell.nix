{ lib }:

let

  mkShellIntegrationOption = name:
    { config, baseName ? name, extraDescription ? "" }:
    let attrName = "enable${baseName}Integration";
    in lib.mkOption {
      default = config.home.shell.${attrName};
      defaultText = lib.literalMD "[](#opt-home.shell.${attrName})";
      example = false;
      description = "Whether to enable ${name} integration.${
          lib.optionalString (extraDescription != "")
          ("\n\n" + extraDescription)
        }";
      type = lib.types.bool;
    };

in rec {
  # Produces a Bourne shell like variable export statement.
  export = n: v: ''export ${n}="${toString v}"'';

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);

  mkBashIntegrationOption = mkShellIntegrationOption "Bash";
  mkFishIntegrationOption = mkShellIntegrationOption "Fish";
  mkIonIntegrationOption = mkShellIntegrationOption "Ion";
  mkNushellIntegrationOption = mkShellIntegrationOption "Nushell";
  mkZshIntegrationOption = mkShellIntegrationOption "Zsh";
}
