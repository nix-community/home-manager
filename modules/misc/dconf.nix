{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.dconf;
  dag = config.lib.dag;

  toDconfIni = generators.toINI { mkKeyValue = mkIniKeyValue; };

  mkIniKeyValue = key: value:
    let
      tweakVal = v:
        if isString v then "'${v}'"
        else if isList v then tweakList v
        else if isBool v then (if v then "true" else "false")
        else toString v;

      # Assume empty list is a list of strings, see #769
      tweakList = v:
        if v == [] then "@as []"
        else "[" + concatMapStringsSep "," tweakVal v + "]";

    in
      "${key}=${tweakVal value}";

  primitive = with types; either bool (either int (either float str));

in

{
  meta.maintainers = [ maintainers.gnidorah maintainers.rycee ];

  options = {
    dconf = {
      enable = mkOption {
        type = types.bool;
        default = true;
        visible = false;
        description = ''
          Whether to enable dconf settings.
        '';
      };

      settings = mkOption {
        type = with types;
          attrsOf (attrsOf (either primitive (listOf primitive)));
        default = {};
        example = literalExample ''
          {
            "org/gnome/calculator" = {
              button-mode = "programming";
              show-thousands = true;
              base = 10;
              word-size = 64;
            };
          }
        '';
        description = ''
          Settings to write to the dconf configuration system.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.settings != {}) {
    home.activation.dconfSettings = dag.entryAfter ["installPackages"] (
      let
        iniFile = pkgs.writeText "hm-dconf.ini" (toDconfIni cfg.settings);
      in
        ''
          if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
            DCONF_DBUS_RUN_SESSION=""
          else
            DCONF_DBUS_RUN_SESSION="${pkgs.dbus}/bin/dbus-run-session"
          fi

          if [[ -v DRY_RUN ]]; then
            echo $DCONF_DBUS_RUN_SESSION ${pkgs.gnome3.dconf}/bin/dconf load / "<" ${iniFile}
          else
            $DCONF_DBUS_RUN_SESSION ${pkgs.gnome3.dconf}/bin/dconf load / < ${iniFile}
          fi

          unset DCONF_DBUS_RUN_SESSION
        ''
    );
  };
}
