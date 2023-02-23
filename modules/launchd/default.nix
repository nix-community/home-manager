{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.generators) toPlist;

  cfg = config.launchd;
  labelPrefix = "org.nix-community.home.";
  dstDir = "${config.home.homeDirectory}/Library/LaunchAgents";

  launchdConfig = { config, name, ... }: {
    options = {
      enable = mkEnableOption name;
      config = mkOption {
        type = types.submodule (import ./launchd.nix);
        default = { };
        example = literalExpression ''
          {
            ProgramArguments = [ "/usr/bin/say" "Good afternoon" ];
            StartCalendarInterval = [
              {
                Hour = 12;
                Minute = 0;
              }
            ];
          }
        '';
        description = ''
          Define a launchd job. See <citerefentry>
          <refentrytitle>launchd.plist</refentrytitle><manvolnum>5</manvolnum>
          </citerefentry> for details.
        '';
      };
    };

    config = { config.Label = mkDefault "${labelPrefix}${name}"; };
  };

  toAgent = config: pkgs.writeText "${config.Label}.plist" (toPlist { } config);

  agentPlists =
    mapAttrs' (n: v: nameValuePair "${v.config.Label}.plist" (toAgent v.config))
    (filterAttrs (n: v: v.enable) cfg.agents);

  agentsDrv = pkgs.runCommand "home-manager-agents" { } ''
    mkdir -p "$out"

    declare -A plists
    plists=(${
      concatStringsSep " "
      (mapAttrsToList (name: value: "['${name}']='${value}'") agentPlists)
    })

    for dest in "''${!plists[@]}"; do
      src="''${plists[$dest]}"
      ln -s "$src" "$out/$dest"
    done
  '';
in {
  meta.maintainers = with maintainers; [ midchildan ];

  options.launchd = {
    enable = mkOption {
      type = types.bool;
      default = isDarwin;
      defaultText = literalExpression "pkgs.stdenv.hostPlatform.isDarwin";
      description = ''
        Whether to enable Home Manager to define per-user daemons by making use
        of launchd's LaunchAgents.
      '';
    };

    agents = mkOption {
      type = with types; attrsOf (submodule launchdConfig);
      default = { };
      description = "Define LaunchAgents.";
    };
  };

  config = mkMerge [
    {
      assertions = [{
        assertion = (cfg.enable && agentPlists != { }) -> isDarwin;
        message = let names = lib.concatStringsSep ", " (attrNames agentPlists);
        in "Must use Darwin for modules that require Launchd: " + names;
      }];
    }

    (mkIf isDarwin {
      home.extraBuilderCommands = ''
        ln -s "${agentsDrv}" $out/LaunchAgents
      '';

      home.activation.checkLaunchAgents =
        hm.dag.entryBefore [ "writeBoundary" ] ''
          checkLaunchAgents() {
            local oldDir newDir dstDir err
            oldDir=""
            err=0
            if [[ -n "''${oldGenPath:-}" ]]; then
              oldDir="$(readlink -m "$oldGenPath/LaunchAgents")" || err=$?
              if (( err )); then
                oldDir=""
              fi
            fi
            newDir=${escapeShellArg agentsDrv}
            dstDir=${escapeShellArg dstDir}

            local oldSrcPath newSrcPath dstPath agentFile agentName

            find -L "$newDir" -maxdepth 1 -name '*.plist' -type f -print0 \
                | while IFS= read -rd "" newSrcPath; do
              agentFile="''${newSrcPath##*/}"
              agentName="''${agentFile%.plist}"
              dstPath="$dstDir/$agentFile"
              oldSrcPath="$oldDir/$agentFile"

              if [[ ! -e "$dstPath" ]]; then
                continue
              fi

              if ! cmp --quiet "$oldSrcPath" "$dstPath"; then
                errorEcho "Existing file '$dstPath' is in the way of '$newSrcPath'"
                exit 1
              fi
            done
          }

          checkLaunchAgents
        '';

      # NOTE: Launch Agent configurations can't be symlinked from the Nix store
      # because it needs to be owned by the user running it.
      home.activation.setupLaunchAgents =
        hm.dag.entryAfter [ "writeBoundary" ] ''
          setupLaunchAgents() {
            local oldDir newDir dstDir domain err
            oldDir=""
            err=0
            if [[ -n "''${oldGenPath:-}" ]]; then
              oldDir="$(readlink -m "$oldGenPath/LaunchAgents")" || err=$?
              if (( err )); then
                oldDir=""
              fi
            fi
            newDir="$(readlink -m "$newGenPath/LaunchAgents")"
            dstDir=${escapeShellArg dstDir}
            domain="gui/$UID"
            err=0

            local srcPath dstPath agentFile agentName i bootout_retries
            bootout_retries=10

            find -L "$newDir" -maxdepth 1 -name '*.plist' -type f -print0 \
                | while IFS= read -rd "" srcPath; do
              agentFile="''${srcPath##*/}"
              agentName="''${agentFile%.plist}"
              dstPath="$dstDir/$agentFile"

              if cmp --quiet "$srcPath" "$dstPath"; then
                continue
              fi
              if [[ -f "$dstPath" ]]; then
                for (( i = 0; i < bootout_retries; i++ )); do
                  $DRY_RUN_CMD /bin/launchctl bootout "$domain/$agentName" || err=$?
                  if [[ -v DRY_RUN ]]; then
                    break
                  fi
                  if (( err != 9216 )) &&
                    ! /bin/launchctl print "$domain/$agentName" &> /dev/null; then
                    break
                  fi
                  sleep 1
                done
                if (( i == bootout_retries )); then
                  warnEcho "Failed to stop '$domain/$agentName'"
                  return 1
                fi
              fi
              $DRY_RUN_CMD install -Dm444 -T "$srcPath" "$dstPath"
              $DRY_RUN_CMD /bin/launchctl bootstrap "$domain" "$dstPath"
            done

            if [[ ! -e "$oldDir" ]]; then
              return
            fi

            find -L "$oldDir" -maxdepth 1 -name '*.plist' -type f -print0 \
                | while IFS= read -rd "" srcPath; do
              agentFile="''${srcPath##*/}"
              agentName="''${agentFile%.plist}"
              dstPath="$dstDir/$agentFile"
              if [[ -e "$newDir/$agentFile" ]]; then
                continue
              fi

              $DRY_RUN_CMD /bin/launchctl bootout "$domain/$agentName" || :
              if [[ ! -e "$dstPath" ]]; then
                continue
              fi
              if ! cmp --quiet "$srcPath" "$dstPath"; then
                warnEcho "Skipping deletion of '$dstPath', since its contents have diverged"
                continue
              fi
              $DRY_RUN_CMD rm -f $VERBOSE_ARG "$dstPath"
            done
          }

          setupLaunchAgents
        '';
    })
  ];
}
