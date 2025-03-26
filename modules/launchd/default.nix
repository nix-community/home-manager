{ config, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.generators) toPlist;

  cfg = config.launchd;
  labelPrefix = "org.nix-community.home.";
  dstDir = "${config.home.homeDirectory}/Library/LaunchAgents";

  launchdConfig = { config, name, ... }: {
    options = {
      enable = lib.mkEnableOption name;
      config = lib.mkOption {
        type = lib.types.submodule (import ./launchd.nix);
        default = { };
        example = lib.literalExpression ''
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
          Define a launchd job. See {manpage}`launchd.plist(5)` for details.
        '';
      };
    };

    config = { config.Label = lib.mkDefault "${labelPrefix}${name}"; };
  };

  toAgent = config: pkgs.writeText "${config.Label}.plist" (toPlist { } config);

  agentPlists = lib.mapAttrs'
    (n: v: lib.nameValuePair "${v.config.Label}.plist" (toAgent v.config))
    (lib.filterAttrs (n: v: v.enable) cfg.agents);

  agentsDrv = pkgs.runCommand "home-manager-agents" { } ''
    mkdir -p "$out"

    declare -A plists
    plists=(${
      lib.concatStringsSep " "
      (lib.mapAttrsToList (name: value: "['${name}']='${value}'") agentPlists)
    })

    for dest in "''${!plists[@]}"; do
      src="''${plists[$dest]}"
      ln -s "$src" "$out/$dest"
    done
  '';
in {
  meta.maintainers = with lib.maintainers; [ khaneliman midchildan ];

  options.launchd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = isDarwin;
      defaultText = lib.literalExpression "pkgs.stdenv.hostPlatform.isDarwin";
      description = ''
        Whether to enable Home Manager to define per-user daemons by making use
        of launchd's LaunchAgents.
      '';
    };

    agents = lib.mkOption {
      type = with lib.types; attrsOf (submodule launchdConfig);
      default = { };
      description = "Define LaunchAgents.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [{
        assertion = (cfg.enable && agentPlists != { }) -> isDarwin;
        message =
          let names = lib.concatStringsSep ", " (lib.attrNames agentPlists);
          in "Must use Darwin for modules that require Launchd: " + names;
      }];
    }

    (lib.mkIf isDarwin {
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
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
            dstDir=${lib.escapeShellArg dstDir}
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
                  run /bin/launchctl bootout "$domain/$agentName" || err=$?
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
              run install -Dm444 -T "$srcPath" "$dstPath"
              run /bin/launchctl bootstrap "$domain" "$dstPath"
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

              run /bin/launchctl bootout "$domain/$agentName" || :
              if [[ ! -e "$dstPath" ]]; then
                continue
              fi
              if ! cmp --quiet "$srcPath" "$dstPath"; then
                warnEcho "Skipping deletion of '$dstPath', since its contents have diverged"
                continue
              fi
              run rm -f $VERBOSE_ARG "$dstPath"
            done
          }

          setupLaunchAgents
        '';
    })
  ];
}
