{ config, lib, pkgs, activationPkgs, ... }:

with lib;

let

  cfg = config.dconf;

  toDconfIni = generators.toINI { mkKeyValue = mkIniKeyValue; };

  mkIniKeyValue = key: value: "${key}=${toString (hm.gvariant.mkValue value)}";

  # The dconf keys managed by this configuration. We store this as part of the
  # generation state to be able to reset keys that become unmanaged during
  # switch.
  stateDconfKeys = pkgs.writeText "dconf-keys.json" (builtins.toJSON
    (concatLists (mapAttrsToList
      (dir: entries: mapAttrsToList (key: _: "/${dir}/${key}") entries)
      cfg.settings)));

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    dconf = {
      enable = mkOption {
        type = types.bool;
        # While technically dconf on darwin could work, our activation step
        # requires dbus, which only *lightly* supports Darwin in general, and
        # not at all in the way it's packaged in nixpkgs. Because of this, we
        # just disable dconf for darwin hosts by default.
        # In the future, if someone gets dbus working, this _could_ be
        # re-enabled, unclear whether there's actual value in it though.
        default = !pkgs.stdenv.hostPlatform.isDarwin;
        visible = false;
        description = ''
          Whether to enable dconf settings.

          Note, if you use NixOS then you must add
          `programs.dconf.enable = true`
          to your system configuration. Otherwise you will see a systemd error
          message when your configuration is activated.
        '';
      };

      settings = mkOption {
        type = with types; attrsOf (attrsOf hm.types.gvariant);
        default = { };
        example = literalExpression ''
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

          Note that the database is strongly-typed so you need to use the same types
          as described in the GSettings schema. For example, if an option is of type
          `uint32` (`u`), you need to wrap the number
          using the `lib.hm.gvariant.mkUint32` constructor.
          Otherwise, since Nix integers are implicitly coerced to `int32`
          (`i`), it would get stored in the database as such, and GSettings
          might be confused when loading the setting.

          You might want to use [dconf2nix](https://github.com/gvolpe/dconf2nix)
          to convert dconf database dumps into compatible Nix expression.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.settings != { }) {
    # Make sure the dconf directory exists.
    xdg.configFile."dconf/.keep".source = builtins.toFile "keep" "";

    home.extraBuilderCommands = ''
      mkdir -p $out/state/
      ln -s ${stateDconfKeys} $out/state/${stateDconfKeys.name}
    '';

    home.activation.dconfSettings = hm.dag.entryAfter [ "installPackages" ] (let
      iniFile =
        activationPkgs.writeText "hm-dconf.ini" (toDconfIni cfg.settings);

      statePath = "state/${stateDconfKeys.name}";

      cleanup = activationPkgs.writeShellScript "dconf-cleanup" ''
        set -euo pipefail

        ${config.lib.bash.initHomeManagerLib}

        PATH=${
          makeBinPath [ activationPkgs.dconf activationPkgs.jq ]
        }''${PATH:+:}$PATH

        oldState="$1"
        newState="$2"

        # Can't do cleanup if we don't know the old state.
        if [[ ! -f $oldState ]]; then
          exit 0
        fi

        # Reset all keys that are present in the old generation but not the new
        # one.
        jq -r -n \
            --slurpfile old "$oldState" \
            --slurpfile new "$newState" \
            '($old[] - $new[])[]' \
          | while read -r key; do
              verboseEcho "Resetting dconf key \"$key\""
              run $DCONF_DBUS_RUN_SESSION dconf reset "$key"
            done
      '';
    in ''
      if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
        export DCONF_DBUS_RUN_SESSION=""
      else
        export DCONF_DBUS_RUN_SESSION="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
      fi

      if [[ -v oldGenPath ]]; then
        ${cleanup} \
          "$oldGenPath/${statePath}" \
          "$newGenPath/${statePath}"
      fi

      run $DCONF_DBUS_RUN_SESSION ${pkgs.dconf}/bin/dconf load / < ${iniFile}

      unset DCONF_DBUS_RUN_SESSION
    '');
  };
}
