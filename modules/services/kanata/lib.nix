{ lib, pkgs }:

let
  allDevices =
    kbd:
    kbd.devices ++ lib.optionals pkgs.stdenv.isLinux (map (id: "/dev/input/by-id/${id}") kbd.deviceIds);

  mkDefcfg =
    _name: kbd:
    let
      devs = allDevices kbd;
      quoted = lib.concatMapStringsSep " " (d: "\"${d}\"") devs;
      devicesLine =
        if devs != [ ] then
          if pkgs.stdenv.isLinux then "linux-dev (${quoted})" else "macos-dev-names-include (${quoted})"
        else
          "";
      lines = lib.filter (s: s != "") [
        devicesLine
        (lib.optionalString (
          pkgs.stdenv.isLinux && kbd.continueIfNoDevsFound
        ) "linux-continue-if-no-devs-found yes")
        (lib.optionalString kbd.processUnmappedKeys "process-unmapped-keys yes")
        kbd.extraDefCfg
      ];
    in
    "(defcfg\n  ${lib.concatStringsSep "\n  " lines}\n)";

  mkDefsrc = keys: "(defsrc\n  ${lib.concatStringsSep "\n  " keys}\n)";

  mkLayers =
    layers:
    lib.concatStringsSep "\n\n" (
      lib.mapAttrsToList (
        layerName: actions: "(deflayer ${layerName}\n  ${lib.concatStringsSep " " actions}\n)"
      ) layers
    );

  mkKanataConfigText =
    name: kbd:
    lib.concatStringsSep "\n\n" (
      [ (mkDefcfg name kbd) ]
      ++ lib.optional (kbd.defsrc != [ ]) (mkDefsrc kbd.defsrc)
      ++ lib.optional (kbd.layers != { }) (mkLayers kbd.layers)
      ++ lib.optional (kbd.extraConfig != "") kbd.extraConfig
    )
    + "\n";

in
{
  inherit mkKanataConfigText allDevices;
}
