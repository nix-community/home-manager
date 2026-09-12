{ lib }:

let
  /*
    Common NixOS-style systemd unit option keys that are mapped to PascalCase
    [Unit] section keys in Home Manager INI unit files.
  */
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

  /*
    Translate a system-level target (e.g. `multi-user.target`) to its user-session
    equivalent (`default.target`).

    Type: normalizeTarget :: String -> String
  */
  normalizeTarget = t: if t == "multi-user.target" then "default.target" else t;

  /*
    Normalize target string or list of target strings.

    Type: normalizeTargets :: (String | List String) -> (String | List String)
  */
  normalizeTargets = v: if lib.isList v then map normalizeTarget v else v;

  /*
    Capitalize the first letter of a string while preserving the rest of its casing.

    Type: upperFirstChar :: String -> String
  */
  upperFirstChar =
    string: lib.toUpper (builtins.substring 0 1 string) + builtins.substring 1 (-1) string;

  /*
    Filter and convert camelCase NixOS unit option keys into PascalCase INI
    section keys using `upperFirstChar`.

    Type: pickSection :: List String -> AttrSet -> AttrSet
  */
  pickSection =
    keys: src:
    lib.listToAttrs (
      lib.concatMap (
        k:
        lib.optional (src ? ${k} && src.${k} != null && src.${k} != [ ]) {
          name = upperFirstChar k;
          value = normalizeTargets src.${k};
        }
      ) keys
    );

  /*
    Convert an environment attribute set into a list of `KEY=VALUE` strings
    for systemd INI `Environment=` settings.

    Type: envToList :: AttrSet -> List String
  */
  envToList =
    env: lib.mapAttrsToList (k: v: "${k}=${toString v}") (lib.filterAttrs (_: v: v != null) env);

  /*
    Construct the `[Install]` INI section mapping `wantedBy` and `requiredBy` to
    normalized user target names.

    Type: installSection :: AttrSet -> AttrSet
  */
  installSection =
    u:
    lib.filterAttrs (_: v: v != [ ]) {
      WantedBy = map normalizeTarget (u.wantedBy or [ ]);
      RequiredBy = map normalizeTarget (u.requiredBy or [ ]);
    };

  /*
    Translate a NixOS-style systemd unit attrset (wantedBy, serviceConfig,
    unitConfig, environment, ...) into the section-based INI shape that
    Home Manager's `systemd.user.<unitType>` expects (Unit/Service/Install).
    Only the common keys are mapped; uncommon options can still be set
    explicitly via `unitConfig` / `serviceConfig` / `socketConfig`.

    Type: toHmIni :: AttrSet -> AttrSet
  */
  toHmIni = unit: {
    Unit = pickSection unitAttrKeys unit // (unit.unitConfig or { });
    Service =
      (unit.serviceConfig or { })
      // lib.optionalAttrs (unit ? environment && unit.environment != { }) {
        Environment = envToList unit.environment;
      };
    Install = installSection unit;
  };

  /*
    Translate a NixOS-style systemd socket unit attrset into the section-based
    INI shape that Home Manager expects (Unit/Socket/Install). Maps
    `listenStreams` and `listenDatagrams` to `ListenStream` and `ListenDatagram`.

    Type: toHmIniSocket :: AttrSet -> AttrSet
  */
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
in
{
  inherit
    unitAttrKeys
    normalizeTarget
    normalizeTargets
    pickSection
    envToList
    installSection
    toHmIni
    toHmIniSocket
    ;
}
