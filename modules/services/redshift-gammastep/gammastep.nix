{ config, lib, pkgs, ... }:

with lib;

let
  commonOptions = import ./lib/options.nix {
    inherit config lib pkgs;

    moduleName = "gammastep";
    programName = "Gammastep";
    # https://gitlab.com/chinstrap/gammastep/-/commit/1608ed61154cc652b087e85c4ce6125643e76e2f
    mainSection = "general";
    defaultPackage = pkgs.gammastep;
    examplePackage = "pkgs.gammastep";
    mainExecutable = "gammastep";
    appletExecutable = "gammastep-indicator";
    xdgConfigFilePath = "gammastep/config.ini";
    serviceDocumentation = "https://gitlab.com/chinstrap/gammastep/";
  };

in {
  inherit (commonOptions) imports meta;
  options.services.gammastep = commonOptions.options;
  config = mkIf config.services.gammastep.enable commonOptions.config;
}
