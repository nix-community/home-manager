{ config, lib, pkgs, ... }:

with lib;
with import ./lib/dag.nix { inherit lib; };

let

  cfg = config.systemd.user;

  enabled = cfg.services != {}
      || cfg.sockets != {}
      || cfg.targets != {}
      || cfg.timers != {};

  toSystemdIni = generators.toINI {
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
      filename = "${name}.${style}";

      # Needed because systemd derives unit names from the ultimate link target
      source = "${pkgs.writeTextDir filename (toSystemdIni serviceCfg)}/${filename}";

      wantedBy = target:
        {
          name = "systemd/user/${target}.wants/${filename}";
          value = { inherit source; };
        };
    in
      singleton {
        name = "systemd/user/${filename}";
        value = { inherit source; };
      }
      ++
      map wantedBy (serviceCfg.Install.WantedBy or []);

  buildServices = style: serviceCfgs:
    concatLists (mapAttrsToList (buildService style) serviceCfgs);

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    systemd.user = {
      systemctlPath = mkOption {
        default = "${pkgs.systemd}/bin/systemctl";
        defaultText = "\${pkgs.systemd}/bin/systemctl";
        type = types.str;
        description = ''
          Absolute path to the <command>systemctl</command> tool. This
          option may need to be set if running Home Manager on a
          non-NixOS distribution.
        '';
      };

      services = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user service units.";
      };

      sockets = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user sockets";
      };

      targets = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user targets";
      };

      timers = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user timers";
      };
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = enabled -> pkgs.stdenv.isLinux;
          message =
            let
              names = concatStringsSep ", " (
                  attrNames (
                      cfg.services // cfg.sockets // cfg.targets // cfg.timers
                  )
              );
            in
              "Must use Linux for modules that require systemd: " + names;
        }
      ];
    }

    # If we run under a Linux system we assume that systemd is
    # available, in particular we assume that systemctl is in PATH.
    (mkIf pkgs.stdenv.isLinux {
      xdg.configFile =
        listToAttrs (
          (buildServices "service" cfg.services)
          ++
          (buildServices "socket" cfg.sockets)
          ++
          (buildServices "target" cfg.targets)
          ++
          (buildServices "timer" cfg.timers)
        );

      home.activation.reloadSystemD = dagEntryAfter ["linkGeneration"] ''
        function isStartable() {
          local service="$1"
          [[ $(systemctl --user show -p RefuseManualStart "$service") == *=no ]]
        }

        function isStoppable() {
          if [[ -v oldGenPath ]] ; then
            local service="$1"
            [[ $(systemctl --user show -p RefuseManualStop "$service") == *=no ]]
          fi
        }

        function systemdPostReload() {
          local workDir
          workDir="$(mktemp -d)"

          if [[ -v oldGenPath ]] ; then
            local oldUserServicePath="$oldGenPath/home-files/.config/systemd/user"
          fi

          local newUserServicePath="$newGenPath/home-files/.config/systemd/user"
          local oldServiceFiles="$workDir/old-files"
          local newServiceFiles="$workDir/new-files"
          local servicesDiffFile="$workDir/diff-files"

          if [[ ! (-v oldUserServicePath && -d "$oldUserServicePath") \
              && ! -d "$newUserServicePath" ]]; then
            return
          fi

          if [[ ! (-v oldUserServicePath && -d "$oldUserServicePath") ]]; then
            touch "$oldServiceFiles"
          else
            find "$oldUserServicePath" \
              -maxdepth 1 -name '*.service' -exec basename '{}' ';' \
              | sort \
              > "$oldServiceFiles"
          fi

          if [[ ! -d "$newUserServicePath" ]]; then
            touch "$newServiceFiles"
          else
            find "$newUserServicePath" \
              -maxdepth 1 -name '*.service' -exec basename '{}' ';' \
              | sort \
              > "$newServiceFiles"
          fi

          diff \
            --new-line-format='+%L' \
            --old-line-format='-%L' \
            --unchanged-line-format=' %L' \
            "$oldServiceFiles" "$newServiceFiles" \
            > $servicesDiffFile || true

          local -a maybeRestart=( $(grep '^ ' $servicesDiffFile | cut -c2-) )
          local -a maybeStop=( $(grep '^-' $servicesDiffFile | cut -c2-) )
          local -a maybeStart=( $(grep '^+' $servicesDiffFile | cut -c2-) )
          local -a toRestart=( )
          local -a toStop=( )
          local -a toStart=( )

          for f in ''${maybeRestart[@]} ; do
            if isStoppable "$f" \
                && isStartable "$f" \
                && ${cfg.systemctlPath} --quiet --user is-active "$f" \
                && ! cmp --quiet \
                    "$oldUserServicePath/$f" \
                    "$newUserServicePath/$f" ; then
              toRestart+=("$f")
            fi
          done

          for f in ''${maybeStop[@]} ; do
            if isStoppable "$f" ; then
              toStop+=("$f")
            fi
          done

          for f in ''${maybeStart[@]} ; do
            if isStartable "$f" ; then
              toStart+=("$f")
            fi
          done

          rm -r $workDir

          local sugg=""

          if [[ -n "''${toRestart[@]}" ]] ; then
            sugg="''${sugg}systemctl --user restart ''${toRestart[@]}\n"
          fi

          if [[ -n "''${toStop[@]}" ]] ; then
            sugg="''${sugg}systemctl --user stop ''${toStop[@]}\n"
          fi

          if [[ -n "''${toStart[@]}" ]] ; then
            sugg="''${sugg}systemctl --user start ''${toStart[@]}\n"
          fi

          if [[ -n "$sugg" ]] ; then
            echo "Suggested commands:"
            echo -n -e "$sugg"
          fi
        }

        $DRY_RUN_CMD ${cfg.systemctlPath} --user daemon-reload
        systemdPostReload
      '';
    })
  ];
}
