{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) concatMapAttrs mkOption types;

  portable-lib = import (pkgs.path + "/lib/services/lib.nix") { inherit lib; };

  # Combine a service-name prefix with a unit name. The empty unit name
  # `""` is the convention from nixpkgs' portable services for the
  # service's *primary* unit (e.g. `services.foo.systemd.user.services.""`
  # is the unit named `foo.service`). Sub-units use a hyphenated suffix.
  dashed =
    before: after:
    if after == "" then
      before
    else if before == "" then
      after
    else
      "${before}-${after}";

  # Translate a NixOS-style systemd unit attrset (wantedBy, serviceConfig,
  # unitConfig, environment, ...) into the section-based INI shape that
  # Home Manager's `systemd.user.<unitType>` expects (Unit/Service/Install).
  # Only the common keys are mapped; uncommon options can still be set
  # explicitly via `unitConfig` / `serviceConfig` / `socketConfig`.
  unitAttrKeys = [
    "description"
    "documentation"
    "requires"
    "wants"
    "upholds"
    "after"
    "before"
    "bindsTo"
    "partOf"
    "conflicts"
    "requisite"
    "onFailure"
    "onSuccess"
  ];
  pickSection =
    keys: src:
    lib.listToAttrs (
      lib.concatMap (
        k:
        lib.optional (src ? ${k} && src.${k} != null && src.${k} != [ ]) {
          name = lib.toSentenceCase k;
          value = src.${k};
        }
      ) keys
    );
  envToList =
    env: lib.mapAttrsToList (k: v: "${k}=${toString v}") (lib.filterAttrs (_: v: v != null) env);
  installSection =
    u:
    lib.filterAttrs (_: v: v != [ ]) {
      WantedBy = u.wantedBy or [ ];
      RequiredBy = u.requiredBy or [ ];
    };
  toHmIni = unit: {
    Unit = pickSection unitAttrKeys unit // (unit.unitConfig or { });
    Service =
      (unit.serviceConfig or { })
      // lib.optionalAttrs (unit ? environment && unit.environment != { }) {
        Environment = envToList unit.environment;
      };
    Install = installSection unit;
  };
  toHmIniSocket = sock: {
    Unit = pickSection unitAttrKeys sock // (sock.unitConfig or { });
    Socket =
      (sock.socketConfig or { })
      // lib.optionalAttrs (sock ? listenStreams && sock.listenStreams != [ ]) {
        ListenStream = sock.listenStreams;
      }
      // lib.optionalAttrs (sock ? listenDatagrams && sock.listenDatagrams != [ ]) {
        ListenDatagram = sock.listenDatagrams;
      };
    Install = installSection sock;
  };

  # Evaluate a deferredModule into attrs, then translate.
  evalDeferred =
    translator: unitModule:
    translator
      (lib.evalModules {
        modules = [
          (_: {
            # Loose schema: NixOS-style unit attrs include nested sub-attrsets
            # (e.g. `serviceConfig`) that need to merge across definitions.
            freeformType =
              with types;
              attrsOf (oneOf [
                (attrsOf raw)
                (listOf raw)
                raw
              ]);
          })
          unitModule
        ];
      }).config;

  makeUnits =
    translator: unitType: prefix: service:
    concatMapAttrs (unitName: unitModule: {
      "${dashed prefix unitName}" = evalDeferred translator unitModule;
    }) service.systemd.${unitType}
    // concatMapAttrs (
      subName: subService: makeUnits translator unitType (dashed prefix subName) subService
    ) service.services;

  # Lift each service's `configData` entries into `xdg.configFile` paths.
  # Mirrors how `nixos/modules/system/service/systemd/system.nix` lifts
  # `configData` to `environment.etc`.
  makeConfigFiles =
    prefix: service:
    lib.mapAttrs' (_: cfg: {
      name = "system-services/${prefix}/${cfg.name}";
      value = lib.filterAttrs (_: v: v != null) {
        source = cfg.source or null;
        text = cfg.text or null;
        inherit (cfg) enable;
      };
    }) (lib.filterAttrs (_: cfg: cfg.enable) (service.configData or { }))
    // concatMapAttrs (
      subName: subService: makeConfigFiles (dashed prefix subName) subService
    ) service.services;

  modularServiceConfiguration = portable-lib.configure {
    serviceManagerPkgs = pkgs;
    extraRootModules = [
      ./service.nix
      ./config-data-path.nix
    ];
    extraRootSpecialArgs = {
      systemdPackage = pkgs.systemd;
      nixpkgsPath = pkgs.path;
      xdgConfigHome = config.xdg.configHome;
    };
  };
in
{
  meta.maintainers = [ lib.maintainers.kiara ];

  options.home.services = mkOption {
    description = ''
      Home Manager [modular services](https://nixos.org/manual/nixos/unstable/#modular-services).

      Each entry is an abstract service that may declare a {option}`process.argv`
      and Home Manager-style {option}`systemd.user.{services,sockets}` units
      (INI section shape). Units are emitted under Home Manager's
      {option}`systemd.user.services` (and friends) with the service name
      as a prefix. Mirrors {option}`system.services` in NixOS.
    '';
    type = types.attrsOf modularServiceConfiguration.serviceSubmodule;
    default = { };
    visible = "shallow";
  };

  config = {
    assertions = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getAssertions [ "home" "services" name ] cfg
      ) config.home.services
    );

    warnings = lib.concatLists (
      lib.mapAttrsToList (
        name: cfg: portable-lib.getWarnings [ "home" "services" name ] cfg
      ) config.home.services
    );

    systemd.user.services = concatMapAttrs (
      name: svc: makeUnits toHmIni "services" name svc
    ) config.home.services;

    systemd.user.sockets = concatMapAttrs (
      name: svc: makeUnits toHmIniSocket "sockets" name svc
    ) config.home.services;

    xdg.configFile = concatMapAttrs (name: svc: makeConfigFiles name svc) config.home.services;
  };
}
