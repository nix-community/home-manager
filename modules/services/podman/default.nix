{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.podman;
  toml = pkgs.formats.toml { };

  registriesCfg = cfg.settings.registries;

  legacyRegistryEntries =
    (map (location: {
      inherit location;
      insecure = true;
    }) registriesCfg.insecure)
    ++ (map (location: {
      inherit location;
      blocked = true;
    }) registriesCfg.block);

  registryEntries = lib.mapAttrsToList (
    location: entries:
    let
      merged =
        builtins.foldl'
          (acc: entry: {
            inherit location;
            insecure = if entry ? insecure && entry.insecure != null then entry.insecure else acc.insecure;
            blocked = if entry ? blocked && entry.blocked != null then entry.blocked else acc.blocked;
          })
          {
            inherit location;
            insecure = null;
            blocked = null;
          }
          entries;
    in
    {
      inherit (merged) location;
    }
    // lib.optionalAttrs (merged.insecure != null) {
      inherit (merged) insecure;
    }
    // lib.optionalAttrs (merged.blocked != null) {
      inherit (merged) blocked;
    }
  ) (lib.groupBy (entry: entry.location) (legacyRegistryEntries ++ registriesCfg.registry));

  registriesConfSettings = {
    unqualified-search-registries = registriesCfg.search;
  }
  // lib.optionalAttrs (registryEntries != [ ]) {
    registry = registryEntries;
  };

  configFiles = {
    "policy.json" =
      if cfg.settings.policy != { } then
        pkgs.writeText "policy.json" (builtins.toJSON cfg.settings.policy)
      else
        "${pkgs.skopeo.policy}/default-policy.json";
    "registries.conf" = toml.generate "registries.conf" registriesConfSettings;
    "storage.conf" = toml.generate "storage.conf" cfg.settings.storage;
    "containers.conf" = toml.generate "containers.conf" cfg.settings.containers;
  }
  // lib.optionalAttrs (cfg.settings.mounts != [ ]) {
    "mounts.conf" = pkgs.writeText "mounts.conf" (builtins.concatStringsSep "\n" cfg.settings.mounts);
  };
in
{
  meta.maintainers = [
    lib.hm.maintainers.bamhm182
    lib.maintainers.n-hass
    lib.maintainers.delafthi
  ];

  imports = [
    ./linux/default.nix
    ./darwin.nix
  ];

  options.services.podman = {
    enable = lib.mkEnableOption "Podman, a daemonless container engine";

    package = lib.mkPackageOption pkgs "podman" { };

    _configFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      internal = true;
      visible = false;
      readOnly = true;
      default = configFiles;
      description = ''
        Attribute set mapping `~/.config/containers/<name>` to the generated
        source path. Consumed by the Linux module to populate `xdg.configFile`
        and by the Darwin module to install the same files as real files into
        `~/.config/containers` for the podman machine bind mount.
      '';
    };

    settings = {
      containers = lib.mkOption {
        inherit (toml) type;
        default = { };
        description = "containers.conf configuration";
      };

      storage = lib.mkOption {
        inherit (toml) type;
        description = "storage.conf configuration";
      };

      registries = {
        search = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "docker.io" ];
          description = ''
            List of repositories to search.
          '';
        };

        insecure = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
          description = ''
            List of insecure repositories.
          '';
        };

        block = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
          description = ''
            List of blocked repositories.
          '';
        };

        registry = lib.mkOption {
          default = [ ];
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                location = lib.mkOption {
                  type = lib.types.str;
                  description = "Registry location.";
                };
                insecure = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  default = null;
                  description = "Whether the registry is insecure.";
                };
                blocked = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  default = null;
                  description = "Whether the registry is blocked.";
                };
              };
            }
          );
          description = ''
            List of per-registry configuration entries.

            Prefer this over the deprecated `insecure` and `block` lists.
          '';
        };
      };

      policy = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        example = {
          default = [ { type = "insecureAcceptAnything"; } ];
          transports = {
            docker-daemon = {
              "" = [ { type = "insecureAcceptAnything"; } ];
            };
          };
        };
        description = ''
          Signature verification policy file.
          If this option is empty the default policy file from
          `skopeo` will be used.
        '';
      };

      mounts = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "mounts.conf configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];

        services.podman.settings.storage.storage.driver = lib.mkDefault "overlay";

        # On Linux, podman reads its configuration directly from
        # `$XDG_CONFIG_HOME/containers`. On Darwin the same files are placed there
        # as real files by an activation script and bind-mounted into the podman
        # machine VM (see darwin.nix).
        xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
          lib.mapAttrs' (name: src: lib.nameValuePair "containers/${name}" { source = src; }) cfg._configFiles
        );
        home.activation.podmanContainersConfig = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
          lib.hm.dag.entryBetween [ "podmanMachines" ] [ "linkGeneration" ] ''
            run mkdir -p "$HOME/.config/containers"

            # Remove only files this module manages.
            for f in ${lib.escapeShellArgs (builtins.attrNames cfg._configFiles)}; do
              run rm -f "$HOME/.config/containers/$f"
            done

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: src: ''run install -m 0644 ${src} "$HOME/.config/containers/${name}"''
              ) cfg._configFiles
            )}
          ''
        );
      }
      (lib.mkIf (registriesCfg.insecure != [ ] || registriesCfg.block != [ ]) {
        warnings = [
          ''
            `services.podman.settings.registries.insecure` and
            `services.podman.settings.registries.block` are deprecated and will be
            removed in a future release.

            Use `services.podman.settings.registries.registry` entries with
            `location`, `insecure`, and `blocked` instead.
          ''
        ];
      })
    ]
  );
}
