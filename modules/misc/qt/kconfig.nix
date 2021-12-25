{ config, pkgs, lib, ... }:

let

  cfg = config.qt.kde.settings;

  toKconfVal = p: v:
    let t = builtins.typeOf v;
    in if t == "set" then
      v
    else if v == null then
      "--delete"
    else if t == "bool" then
      "--type bool ${builtins.toJSON v}"
    else
      toString v;

in {
  options.qt.kde.settings = lib.mkOption {
    type = with lib.types;
      let
        valueType =
          nullOr (oneOf [ bool int float str path (attrsOf valueType) ]) // {
            description = "KDE option value";
          };
      in attrsOf valueType;
    default = { };
    example = {
      powermanagementprofilesrc.AC.HandleButtonEvents.lidAction = 32;
    };
    description = ''
      A set of values to be modified by {command}`kwriteconfig5`.

      The example value would cause the following command to run in the
      activation script:

      ``` shell
      kwriteconfig5 --file $XDG_CONFIG_HOME/powermanagementprofilesrc \
                    --group AC \
                    --group HandleButtonEvents \
                    --group lidAction \
                    --key lidAction \
                    32
      ```

      Note, `null` values will delete the corresponding entry instead of
      inserting any value.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.activation.kconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      . ${
        pkgs.runCommandLocal "kwriteconfig.sh" {
          nativeBuildInputs = [ pkgs.jq ];
          passAsFile = [ "cfg" "jqScript" ];
          cfg = builtins.toJSON (lib.mapAttrsRecursive toKconfVal cfg);
          jqScript = let
            getPaths = "[paths(scalars)]";
            w =
              "run ${pkgs.plasma5Packages.kconfig}/bin/kwriteconfig5 --file ${config.xdg.configHome}/";
            g = ''" --group "'';
            groupPortion = ".[1:-2]|join(${g})";
            getVal = "$G|getpath($P)";
            mkExecLn = ''
              "${w}"+.[0]+${g}+(${groupPortion})+" --key "+.[-1]+(${getVal})'';
            toSingleStr = ''join("\n")'';
          in ". as $G|${getPaths}|map(. as $P|${mkExecLn})|${toSingleStr}";
        } ''jq -rf "$jqScriptPath" <"$cfgPath" >"$out"''
      }

      # TODO: some way to only call the dbus calls needed
      run ${pkgs.libsForQt5.qt5.qttools.bin}/bin/qdbus org.kde.KWin /KWin reconfigure || echo "KWin reconfigure failed"
      # the actual values are https://github.com/KDE/plasma-workspace/blob/c97dddf20df5702eb429b37a8c10b2c2d8199d4e/kcms/kcms-common_p.h#L13
      for changeType in {0..10}; do
        run ${pkgs.dbus}/bin/dbus-send /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:$changeType int32:0 || echo "KGlobalSettings.notifyChange failed"
      done
    '';
  };
}
