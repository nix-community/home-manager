{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  (
    let
      commonOptions = import ./options.nix {
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

    in
    {
      inherit (commonOptions) imports meta;
      options.services.gammastep = commonOptions.options;
      config = lib.mkIf config.services.gammastep.enable commonOptions.config;
    }
  )
  (
    let
      commonOptions = import ./options.nix {
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
  )
]
