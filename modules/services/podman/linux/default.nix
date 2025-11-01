{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.podman;
  toml = pkgs.formats.toml { };
in
{
  imports = [
    ./options.nix
    ./builds.nix
    ./containers.nix
    ./images.nix
    ./install-quadlet.nix
    ./networks.nix
    ./services.nix
    ./volumes.nix
  ];

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ cfg.package ];

    services.podman.settings.storage = {
      storage.driver = lib.mkDefault "overlay";
    };

    xdg.configFile = {
      "containers/policy.json".source =
        if cfg.settings.policy != { } then
          pkgs.writeText "policy.json" (builtins.toJSON cfg.settings.policy)
        else
          "${pkgs.skopeo.policy}/default-policy.json";
      "containers/registries.conf".source = toml.generate "registries.conf" {
        registries = lib.mapAttrs (n: v: { registries = v; }) cfg.settings.registries;
      };
      "containers/storage.conf".source = toml.generate "storage.conf" cfg.settings.storage;
      "containers/containers.conf".source = toml.generate "containers.conf" cfg.settings.containers;
      "containers/mounts.conf" = lib.mkIf (cfg.settings.mounts != [ ]) {
        text = builtins.concatStringsSep "\n" cfg.settings.mounts;
      };
    };
  };
}
