{ config, pkgs, lib, ... }:

let

  cfg = config.qt.kde.settings;
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
      ${let
        inherit (config.xdg) configHome;
        toValue = v:
          let t = builtins.typeOf v;
          in if v == null then
            "--delete"
          else if t == "bool" then
            "--type bool ${builtins.toJSON v}"
          else
            lib.escapeShellArg (toString v);
        toLine = file: path: value:
          if builtins.isAttrs value then
            lib.mapAttrsToList
            (group: value: toLine file (path ++ [ group ]) value) value
          else
            "run test -f '${configHome}/${file}' && run ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file '${configHome}/${file}' ${
              lib.concatMapStringsSep " " (x: "--group ${x}")
              (lib.lists.init path)
            } --key '${lib.lists.last path}' ${toValue value}";
        lines = lib.flatten
          (lib.mapAttrsToList (file: attrs: toLine file [ ] attrs) cfg);
      in builtins.concatStringsSep "\n" lines}

      # TODO: some way to only call the dbus calls needed
      run ${pkgs.libsForQt5.qttools.bin}/bin/qdbus org.kde.KWin /KWin reconfigure || echo "KWin reconfigure failed"
      # the actual values are https://github.com/KDE/plasma-workspace/blob/c97dddf20df5702eb429b37a8c10b2c2d8199d4e/kcms/kcms-common_p.h#L13
      for changeType in {0..10}; do
        # even if one of those calls fails the others keep running
        run ${pkgs.dbus}/bin/dbus-send /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:$changeType int32:0 || echo "KGlobalSettings.notifyChange $changeType failed"
      done
    '';
  };
}
