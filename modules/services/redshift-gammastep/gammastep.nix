{ config, lib, pkgs, ... }:

with lib;

let
  commonOptions = import ./lib/options.nix {
    inherit config lib;

    moduleName = "gammastep";
    programName = "Gammastep";
    defaultPackage = pkgs.gammastep;
    examplePackage = "pkgs.gammastep";
    mainExecutable = "gammastep";
    appletExecutable = "gammastep-indicator";
    serviceDocumentation = "https://gitlab.com/chinstrap/gammastep/";
  };

in {
  meta = commonOptions.meta;
  options.services.gammastep = commonOptions.options;
  config = mkIf config.services.gammastep.enable commonOptions.config;
}
