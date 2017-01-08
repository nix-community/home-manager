{ config, lib, pkgs, ... }:

with lib;

let

  toSystemdIni = (import lib/generators.nix).toINI {
    mkKeyValue = key: value:
      let
        value' =
          if isBool value then (if value then "true" else "false")
          else toString value;
      in
        "${key}=${value'}";
  };

  buildService = style: name: serviceCfg:
    let
      source = pkgs.writeText "${name}.${style}" (toSystemdIni serviceCfg);

      wantedBy = target:
        {
          name = ".config/systemd/user/${target}.wants/${name}.${style}";
          value = { inherit source; };
        };
    in
      singleton {
        name = ".config/systemd/user/${name}.${style}";
        value = { inherit source; };
      }
      ++
      map wantedBy (serviceCfg.Install.WantedBy or []);

  buildServices = style: serviceCfgs:
    concatLists (mapAttrsToList (buildService style) serviceCfgs);

in

{
  options = {
    systemd.user = {
      services = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user service units.";
      };

      timers = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user timers";
      };
    };
  };

  config = {
    home.file =
      listToAttrs (
        (buildServices "service" config.systemd.user.services)
        ++
        (buildServices "timer" config.systemd.user.timers)
      );

    home.activation.reloadSystemD = stringAfter ["linkages"] ''
      function systemdPostReload() {
        local servicesDiffFile="$(mktemp)"
        local oldUserServicePath="$oldGenPath/home-files/.config/systemd/user"
        local newUserServicePath="$newGenPath/home-files/.config/systemd/user"

        diff \
          --new-line-format='+%L' \
          --old-line-format='-%L' \
          --unchanged-line-format=' %L' \
          <(basename -a $(echo "$oldUserServicePath/*.service") | sort) \
          <(basename -a $(echo "$newUserServicePath/*.service") | sort) \
          > $servicesDiffFile

        local -a maybeRestart=( $(grep '^ ' $servicesDiffFile | cut -c2-) )
        local -a toStop=( $(grep '^-' $servicesDiffFile | cut -c2-) )
        local -a toStart=( $(grep '^+' $servicesDiffFile | cut -c2-) )
        local -a toRestart=( )

        for f in ''${maybeRestart[@]} ; do
          if systemctl --quiet --user is-active "$f" \
             && ! cmp --quiet \
                 "$oldUserServicePath/$f" \
                 "$newUserServicePath/$f" ; then
            echo "Adding '$f' to restart list";
            toRestart+=("$f")
          fi
        done

        rm $servicesDiffFile

        local sugg=""

        if [[ -n "''${toRestart[@]}" ]] ; then
          sugg="$sugg\nsystemctl --user restart ''${toRestart[@]}"
        fi

        if [[ -n "''${toStop[@]}" ]] ; then
          sugg="$sugg\nsystemctl --user stop ''${toStop[@]}"
        fi

        if [[ -n "''${toStart[@]}" ]] ; then
          sugg="$sugg\nsystemctl --user start ''${toStart[@]}"
        fi

        if [[ -n "$sugg" ]] ; then
          echo "Suggested commands:"
          echo -e "$sugg"
        fi
      }

      systemctl --user daemon-reload
      systemdPostReload
    '';
  };
}
