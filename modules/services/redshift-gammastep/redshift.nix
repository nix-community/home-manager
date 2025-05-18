{
  config,
  lib,
  pkgs,
  ...
}:
let
  commonOptions = import ./lib/options.nix {
    inherit config lib pkgs;

    moduleName = "redshift";
    programName = "Redshift";
    mainSection = "redshift";
    defaultPackage = pkgs.redshift;
    examplePackage = "pkgs.redshift";
    mainExecutable = "redshift";
    appletExecutable = "redshift-gtk";
    xdgConfigFilePath = "redshift/redshift.conf";
    serviceDocumentation = "http://jonls.dk/redshift/";
  };

in
{
  inherit (commonOptions) imports meta;
  options.services.redshift = commonOptions.options;
  config = lib.mkIf config.services.redshift.enable commonOptions.config;
}
