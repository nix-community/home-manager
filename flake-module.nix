{ lib, flake-parts-lib, moduleLocation, ... }:
let inherit (lib) toString mapAttrs mkOption types;
in {
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      homeConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated Home-Manager configurations.

          `homeConfigurations` is for specific installations. If you want to expose
          reusable configurations, add them to `homeModules` in the form of modules, so
          that you can reference them in this or another flake's `homeConfigurations`.
        '';
      };
      homeModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
        apply = mapAttrs (k: v: {
          _file = "${toString moduleLocation}#homeModules.${k}";
          imports = [ v ];
        });
        description = ''
          Home-Manager modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
