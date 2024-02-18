{ lib, ... }: 

with lib;

let
  primitive = with types; nullOr (oneOf [ bool int str path ]);
  primitiveAttrs = with types; attrsOf (either primitive (listOf primitive));

  formatPrimitiveValue = value:
    if isBool value then
      (if value then "true" else "false")
    else if isList value then
      concatStringsSep " " (map toString value)
    else
      toString value;
in {
  primitive = primitive; # export
  primitiveAttrs = primitiveAttrs; # export

  serviceConfigTypeRules = {
    Restart = types.enum [ "no" "always" "on-failure" "unless-stopped" ];
    TimeoutStopSec = types.int;
  };
  serviceConfigDefaults = {
    Restart = "always";
    TimeoutStopSec = 30;
    ExecStartPre = null;
  };
  serviceConfigType = with types; attrsOf (either primitive (listOf primitive));

  unitConfigTypeRules = {
    After = with types; nullOr (listOf str);
  };
  unitConfigDefaults = {
    After = null;
  };
  unitConfigType = with types; attrsOf (either primitive (listOf primitive));

  assertConfigTypes = configTypeRules: config: containerName:
    lib.flatten (lib.mapAttrsToList (name: value:
      if lib.hasAttr name configTypeRules then
        [{
          assertion = configTypeRules.${name}.check value;
          message = "in '${containerName}' config. ${name}: '${toString value}' does not match expected type: ${configTypeRules.${name}.description}";
        }]
      else []
    ) config);

  formatPrimitiveValue = formatPrimitiveValue; # export

  formatExtraConfig = extraConfig:
    let
      nonNullConfig = lib.filterAttrs (name: value: value != null) extraConfig;
    in
      concatStringsSep "\n" (
        mapAttrsToList (name: value: "${name}=${formatPrimitiveValue value}") nonNullConfig
      );
}