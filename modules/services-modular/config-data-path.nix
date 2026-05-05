# Sets `path` on each modular service's `configData.<name>` so that the
# service can refer to its config files at a stable absolute location
# inside the user's XDG config directory. Mirrors
# `nixos/modules/system/service/systemd/config-data-path.nix`.
let
  setPathsModule =
    prefix:
    {
      lib,
      name,
      xdgConfigHome,
      ...
    }:
    let
      inherit (lib) mkOption types;
      servicePrefix = "${prefix}${name}";
    in
    {
      _class = "service";
      options = {
        configData = mkOption {
          type = types.lazyAttrsOf (
            types.submodule (
              { config, ... }:
              {
                config.path = lib.mkDefault "${xdgConfigHome}/home-services/${servicePrefix}/${config.name}";
              }
            )
          );
        };
        services = mkOption {
          type = types.attrsOf (
            types.submoduleWith {
              modules = [ (setPathsModule "${servicePrefix}-") ];
              specialArgs = { inherit xdgConfigHome; };
            }
          );
        };
      };
    };
in
setPathsModule ""
