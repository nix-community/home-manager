{ config, lib, pkgs, ... }:

with lib;

let
  commonOptions = import ./lib/options.nix {
    inherit config lib;

    moduleName = "redshift";
    programName = "Redshift";
    defaultPackage = pkgs.redshift;
    examplePackage = "pkgs.redshift";
    mainExecutable = "redshift";
    appletExecutable = "redshift-gtk";
    serviceDocumentation = "http://jonls.dk/redshift/";
  };

in {
  meta = commonOptions.meta;
  options.services.redshift = commonOptions.options;
  config = mkIf config.services.redshift.enable commonOptions.config;
}
