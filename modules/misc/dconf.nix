{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.dconf;

  toDconfIni = generators.toINI { mkKeyValue = mkIniKeyValue; };

  mkIniKeyValue = key: value:
    "${key}=${toString (hm.gvariant.mkValue value)}";

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
        type = with types; attrsOf (attrsOf hm.types.gvariant);
        default = {};
        example = literalExample ''
          {
            "org/gnome/calculator" = {
              button-mode = "programming";
              show-thousands = true;
              base = 10;
              word-size = 64;
              window-position = lib.hm.gvariant.mkTuple [100 100];
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
    home.activation.dconfSettings = hm.dag.entryAfter ["installPackages"] (
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
            echo $DCONF_DBUS_RUN_SESSION ${pkgs.dconf}/bin/dconf load / "<" ${iniFile}
          else
            $DCONF_DBUS_RUN_SESSION ${pkgs.dconf}/bin/dconf load / < ${iniFile}
          fi

          unset DCONF_DBUS_RUN_SESSION
        ''
    );
  };
}
