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
          Define a launchd job. See {manpage}`launchd.plist(5)` for details.
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

      # NOTE: Launch Agent configurations can't be symlinked from the Nix store
      # because it needs to be owned by the user running it.
      home.activation.setupLaunchAgents =
        hm.dag.entryAfter [ "writeBoundary" ] # Bash
        ''
          setupLaunchAgents() {
            local oldDir newDir dstDir domain err
            oldDir=""
            err=0
            if [[ -n "''${oldGenPath:-}" ]]; then
              oldDir="$(readlink -m "$oldGenPath/LaunchAgents")" || err=$?
              verboseEcho $oldDir
              if (( err )); then
                oldDir=""
                verboseEcho "No previous LaunchAgents directory found"
              fi
            fi
            newDir="$(readlink -m "$newGenPath/LaunchAgents")"
            dstDir=${escapeShellArg dstDir}
            domain="gui/$UID"
            err=0

            verboseEcho "Setting up LaunchAgents in $dstDir"
            [[ -d "$dstDir" ]] || run mkdir -p "$dstDir"

            local srcPath dstPath agentFile agentName i bootout_retries
            local updated_count=0 failed_count=0 removed_count=0
            bootout_retries=10

            verboseEcho "Processing new/updated LaunchAgents..."
            find -L "$newDir" -maxdepth 1 -name '*.plist' -type f -print0 \
                | while IFS= read -rd "" srcPath; do
              agentFile="''${srcPath##*/}"
              agentName="''${agentFile%.plist}"
              dstPath="$dstDir/$agentFile"

              if cmp --quiet "$srcPath" "$dstPath"; then
                verboseEcho "Agent '$domain/$agentName' is already up-to-date"
                continue
              fi

              verboseEcho "Processing agent '$agentName'"

              if [[ -f "$dstPath" ]]; then
                verboseEcho "Stopping existing agent '$domain/$agentName'..."
                for (( i = 0; i < bootout_retries; i++ )); do
                  if (( i > 0 )); then
                    verboseEcho "Retry $i/$bootout_retries stopping agent '$agentName'..."
                  fi

                  run /bin/launchctl bootout "$domain/$agentName" || err=$?

                  if [[ -v DRY_RUN ]]; then
                    verboseEcho "DRY_RUN: Would stop agent '$agentName'"
                    break
                  fi

                  if (( err != 9216 )) &&
                    ! run /bin/launchctl print "$domain/$agentName" &> /dev/null; then
                    verboseEcho "Successfully stopped agent '$agentName'"
                    break
                  fi

                  if (( i < bootout_retries - 1 )); then
                    verboseEcho "Agent '$agentName' still running, waiting before retry..."
                    sleep 1
                  fi
                done

                if (( i == bootout_retries )); then
                  warnEcho "Failed to stop agent '$domain/$agentName' after $bootout_retries attempts"
                  failed_count=$((failed_count + 1))
                  return 1
                fi
              else
                verboseEcho "Installing new agent '$agentName'"
              fi

              verboseEcho "Installing agent file to $dstPath"
              run install -Dm444 -T "$srcPath" "$dstPath"

              verboseEcho "Bootstrapping agent '$domain/$agentName'"
              if ! run /bin/launchctl bootstrap "$domain" "$dstPath"; then
                errorEcho "Failed to bootstrap agent '$domain/$agentName'"
                failed_count=$((failed_count + 1))
              else
                verboseEcho "Successfully bootstrapped agent '$domain/$agentName'"
                updated_count=$((updated_count + 1))
              fi
            done

            if [[ ! -e "$oldDir" ]]; then
              verboseEcho "LaunchAgents setup complete: $updated_count updated, $failed_count failed"
              return
            fi

            verboseEcho "Cleaning up removed LaunchAgents..."
            find -L "$oldDir" -maxdepth 1 -name '*.plist' -type f -print0 \
                | while IFS= read -rd "" srcPath; do
              agentFile="''${srcPath##*/}"
              agentName="''${agentFile%.plist}"
              dstPath="$dstDir/$agentFile"

              if [[ -e "$newDir/$agentFile" ]]; then
                verboseEcho "Agent '$agentName' still exists in new generation, skipping cleanup"
                continue
              fi

              verboseEcho "Removing agent '$domain/$agentName'..."
              if ! run /bin/launchctl bootout "$domain/$agentName"; then
                warnEcho "Failed to stop agent '$domain/$agentName', it may already be stopped"
              else
                verboseEcho "Successfully stopped agent '$domain/$agentName'"
              fi

              if [[ ! -e "$dstPath" ]]; then
                verboseEcho "Agent file '$dstPath' already removed"
                continue
              fi

              if ! cmp --quiet "$srcPath" "$dstPath"; then
                warnEcho "Skipping deletion of '$dstPath', since its contents have diverged"
                continue
              fi

              verboseEcho "Removing agent file '$dstPath'"
              if run rm -f $VERBOSE_ARG "$dstPath"; then
                verboseEcho "Successfully removed agent file for '$agentName'"
                removed_count=$((removed_count + 1))
              else
                warnEcho "Failed to remove agent file '$dstPath'"
                failed_count=$((failed_count + 1))
              fi
            done

            verboseEcho "LaunchAgents setup complete: $updated_count updated, $removed_count removed, $failed_count failed"
          }

          setupLaunchAgents
        '';
    })
  ];
}
