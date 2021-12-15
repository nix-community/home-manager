{ config, pkgs, lib, ... }:
let
  cfg = config.qt.kde.settings;
  inherit (builtins) toJSON;
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
    type = lib.types.anything;
    default = { };
    example = lib.literalExpression ''
      { powermanagementprofilesrc.AC.HandleButtonEvents.lidAction = 32;}
    '';
    description = ''
      A set of values to be modified by kwriteconfig5.

      The example value would run in the activation script
      kwriteconfig5 --file $HDG_CONFIG_HOME/powermanagementprofilesrc --group AC --group HandleButtonEvents --group lidAction --key lidAction 32
      .

      null values will delete the corresponding entry instead of inserting any value.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.activation.kconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source ${
        pkgs.runCommandLocal "kwriteconfig.sh" {
          passAsFile = [ "cfg" "jqScript" ];
          cfg = toJSON (lib.mapAttrsRecursive toKconfVal cfg);
          jqScript = ''
            . as $cfg|[
              paths(strings)|
              (. as $p|$cfg|getpath($p)) as $el|
              .[0] as $file|
              .[-1] as $key|
              .[1:-2]|map("--group '\(.)'")|join(" ")|
              "$DRY_RUN_CMD ${pkgs.plasma5Packages.kconfig}/bin/kwriteconfig5 --file '${config.xdg.configHome}/\($file)' \(.) --key \($key) \($el)"
            ]|join("\n")
          '';
        } ''${pkgs.jq}/bin/jq -rf "$jqScriptPath" <"$cfgPath" >"$out"''
      }

      # TODO: some way to only call the dbus calls needed
      $DRY_RUN_CMD ${pkgs.libsForQt5.qt5.qttools.bin}/bin/qdbus org.kde.KWin /KWin reconfigure || echo "KWin reconfigure failed"
      # the actual values are https://github.com/KDE/plasma-workspace/blob/c97dddf20df5702eb429b37a8c10b2c2d8199d4e/kcms/kcms-common_p.h#L13
      for changeType in {0..10}; do
        $DRY_RUN_CMD ${pkgs.dbus}/bin/dbus-send /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:$changeType int32:0 || echo "KGlobalSettings.notifyChange $changeType failed"
      done
    '';
  };

}
