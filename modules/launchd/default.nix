{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.generators) toPlist;

  cfg = config.launchd;
  labelPrefix = "org.nix-community.home.";
  dstDir = "${config.home.homeDirectory}/Library/LaunchAgents";

  launchdConfig =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption name;
        domain = lib.mkOption {
          type = lib.types.enum [
            "gui"
            "user"
          ];
          default = "gui";
          example = "user";
          description = ''
            The launchd domain to bootstrap this agent into.

            The `gui` domain is appropriate for agents that need the user's
            Aqua session, such as window managers, hotkey daemons, and other
            graphical tools. The `user` domain is appropriate for background
            services that do not require a graphical login session.
          '';
        };
        config = lib.mkOption {
          type = lib.types.submodule (import ./launchd.nix);
          default = { };
          example = {
            ProgramArguments = [
              "/usr/bin/say"
              "Good afternoon"
            ];
            StartCalendarInterval = [
              {
                Hour = 12;
                Minute = 0;
              }
            ];
          };
          description = ''
            Define a launchd job. See {manpage}`launchd.plist(5)` for details.
          '';
        };
      };

      config = lib.mkMerge [
        {
          config.Label = lib.mkDefault "${labelPrefix}${name}";
        }
        (lib.mkIf (config.domain == "user") {
          config.LimitLoadToSessionType = lib.mkDefault "Background";
        })
      ];
    };

  # mutateConfig calls /bin/sh with /bin/wait4path to wait for /nix/store before
  # running the original Program and ProgramArguments. This is intentional to
  # fix the issue where launchd starts the agent before /nix/store is ready
  # (before the Nix store is mounted.)
  mutateConfig =
    cnf:
    let
      args =
        lib.optional (cnf.Program != null) cnf.Program
        ++ lib.optionals (cnf.ProgramArguments != null) cnf.ProgramArguments;
    in
    (removeAttrs cnf [
      "Program"
      "ProgramArguments"
    ])
    // {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec ${lib.escapeShellArgs args}"
      ];
    };

  toAgent =
    config: pkgs.writeText "${config.Label}.plist" (toPlist { escape = true; } (mutateConfig config));

  agentPlists = lib.mapAttrs' (
    _n: v: lib.nameValuePair "${v.config.Label}.plist" (toAgent v.config)
  ) (lib.filterAttrs (_n: v: v.enable) cfg.agents);

  agentDomains = lib.mapAttrs' (
    _n: v:
    lib.nameValuePair "${v.config.Label}.domain" (
      pkgs.writeText "${v.config.Label}.domain" "${v.domain}\n"
    )
  ) (lib.filterAttrs (_n: v: v.enable) cfg.agents);

  agentsDrv = pkgs.runCommand "home-manager-agents" { } ''
    mkdir -p "$out"

    declare -A plists
    plists=(${
      lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "['${name}']='${value}'") agentPlists)
    })

    for dest in "''${!plists[@]}"; do
      src="''${plists[$dest]}"
      ln -s "$src" "$out/$dest"
    done
  '';

  agentDomainsDrv = pkgs.runCommand "home-manager-agent-domains" { } ''
    mkdir -p "$out"

    declare -A domains
    domains=(${
      lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "['${name}']='${value}'") agentDomains)
    })

    for dest in "''${!domains[@]}"; do
      src="''${domains[$dest]}"
      ln -s "$src" "$out/$dest"
    done
  '';
in
{
  meta.maintainers = with lib.maintainers; [
    khaneliman
    midchildan
  ];

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
      assertions = [
        {
          assertion = (cfg.enable && agentPlists != { }) -> isDarwin;
          message =
            let
              names = lib.concatStringsSep ", " (lib.attrNames agentPlists);
            in
            "Must use Darwin for modules that require Launchd: " + names;
        }
      ];
    }

    (lib.mkIf isDarwin {
      home.extraBuilderCommands = ''
        ln -s "${agentsDrv}" $out/LaunchAgents
        ln -s "${agentDomainsDrv}" $out/LaunchAgentDomains
      '';

      # NOTE: Launch Agent configurations can't be symlinked from the Nix store
      # because it needs to be owned by the user running it.
      home.activation.setupLaunchAgents =
        lib.hm.dag.entryAfter [ "writeBoundary" ] # Bash
          ''
            # Get the OS version to see if we can use --wait
            version="$(/usr/bin/sw_vers --productVersion | cut -d. -f 1)"

            # Disable errexit to ensure we process all agents even if some fail
            set +e

            readAgentDomain() {
              local domainsDir="$1"
              local agentName="$2"
              local domainFile="$domainsDir/$agentName.domain"

              if [[ -n "$domainsDir" && -f "$domainFile" ]]; then
                local domainName
                domainName="$(<"$domainFile")"
                case "$domainName" in
                  gui|user)
                    printf '%s\n' "$domainName"
                    ;;
                  *)
                    printf 'gui\n'
                    ;;
                esac
              else
                printf 'gui\n'
              fi
            }

            resolveDomain() {
              local domainName="$1"

              case "$domainName" in
                gui)
                  printf 'gui/%s\n' "$UID"
                  ;;
                user)
                  printf 'user/%s\n' "$UID"
                  ;;
              esac
            }

            agentIsLoaded() {
              local domain="$1"
              local agentName="$2"

              run /bin/launchctl print "$domain/$agentName" >/dev/null 2>&1
            }

            # Stop an agent if it's running
            bootoutAgent() {
              local domain="$1"
              local agentName="$2"

              verboseEcho "Stopping agent '$domain/$agentName'..."
              local bootout_output

              if [[ "$version" -ge "26" ]]; then
                if bootout_output=$(run /bin/launchctl bootout --wait "$domain/$agentName" 2>&1); then
                  # --wait already makes sure it was unloaded (BUT we can only use it in >=26)
                  return 0
                fi
              else
                if bootout_output=$(run /bin/launchctl bootout "$domain/$agentName" 2>&1); then
                  # Otherwise on <26 give the system a moment to fully unload the agent
                  run sleep 1
                  return 0
                fi
              fi

              # At this point we know exit code is not 0 because otherwise we
              # would have returned by now

              # Only show warning if it's not the common "No such process" error
              if [[ "$bootout_output" != *"No such process"* ]]; then
                warnEcho "Failed to stop agent '$domain/$agentName': $bootout_output"
                return 1
              else
                verboseEcho "Agent '$domain/$agentName' was not running"
                return 2
              fi
            }

            installAgentFile() {
              local srcPath="$1"
              local dstPath="$2"
              local agentName="$3"

              verboseEcho "Installing agent file to $dstPath"
              if ! run install -Dm444 -T "$srcPath" "$dstPath"; then
                errorEcho "Failed to install agent file for '$agentName'"
                return 1
              fi

              return 0
            }

            bootstrapAgent() {
              local domain="$1"
              local dstPath="$2"
              local agentName="$3"

              verboseEcho "Starting agent '$domain/$agentName'"
              local bootstrap_output
              bootstrap_output=$(run /bin/launchctl bootstrap "$domain" "$dstPath" 2>&1) || {
                if [[ "$bootstrap_output" == *"Bootstrap failed: 5: Input/output error"* ]]; then
                  errorEcho "Failed to start agent '$domain/$agentName' with I/O error (code 5)"
                  errorEcho "This typically happens when the agent wasn't unloaded before attempting to bootstrap the new agent."
                else
                  errorEcho "Failed to start agent '$domain/$agentName' with error: $bootstrap_output"
                fi

                return 1
              }

              verboseEcho "Successfully started agent '$domain/$agentName'"
              return 0
            }

            restoreAgent() {
              local oldSrcPath="$1"
              local dstPath="$2"
              local oldDomain="$3"
              local agentName="$4"

              if [[ ! -f "$oldSrcPath" ]]; then
                warnEcho "Cannot restore previous agent '$oldDomain/$agentName', old file '$oldSrcPath' is missing"
                return 1
              fi

              warnEcho "Restoring previous agent '$oldDomain/$agentName'"
              installAgentFile "$oldSrcPath" "$dstPath" "$agentName" \
                && bootstrapAgent "$oldDomain" "$dstPath" "$agentName"
            }

            processAgent() {
              local srcPath="$1"
              local dstDir="$2"
              local oldDir="$3"
              local oldDomainsDir="$4"
              local newDomainsDir="$5"

              local agentFile="''${srcPath##*/}"
              local agentName="''${agentFile%.plist}"
              local dstPath="$dstDir/$agentFile"
              local oldSrcPath=""
              local oldDomainName
              local newDomainName
              local oldDomain
              local newDomain
              local oldAgentBootedOut=0

              oldDomainName="$(readAgentDomain "$oldDomainsDir" "$agentName")"
              newDomainName="$(readAgentDomain "$newDomainsDir" "$agentName")"
              oldDomain="$(resolveDomain "$oldDomainName")"
              newDomain="$(resolveDomain "$newDomainName")"
              if [[ -n "$oldDir" ]]; then
                oldSrcPath="$oldDir/$agentFile"
              fi

              # Skip if unchanged
              if cmp -s "$srcPath" "$dstPath" && [[ "$oldDomainName" == "$newDomainName" ]]; then
                if agentIsLoaded "$newDomain" "$agentName"; then
                  verboseEcho "Agent '$newDomain/$agentName' is already up-to-date"
                  return 0
                else
                  verboseEcho "Agent '$newDomain/$agentName' is up-to-date but not loaded"
                fi
              fi

              verboseEcho "Processing agent '$newDomain/$agentName'"

              # Stop/Unload agent if it's already running
              if [[ -f "$dstPath" ]]; then
                bootoutAgent "$oldDomain" "$agentName"
                case "$?" in
                  0)
                    oldAgentBootedOut=1
                    ;;
                  2)
                    ;;
                  *)
                    return 1
                    ;;
                esac
              fi

              if [[ "$oldDomainName" != "$newDomainName" ]]; then
                bootoutAgent "$newDomain" "$agentName"
                case "$?" in
                  0|2)
                    ;;
                  *)
                    if [[ "$oldAgentBootedOut" -eq 1 ]]; then
                      restoreAgent "$oldSrcPath" "$dstPath" "$oldDomain" "$agentName"
                    fi
                    return 1
                    ;;
                esac
              fi

              if ! installAgentFile "$srcPath" "$dstPath" "$agentName"; then
                if [[ "$oldAgentBootedOut" -eq 1 ]]; then
                  restoreAgent "$oldSrcPath" "$dstPath" "$oldDomain" "$agentName"
                fi
                return 1
              fi

              if bootstrapAgent "$newDomain" "$dstPath" "$agentName"; then
                return 0
              fi

              if [[ "$oldAgentBootedOut" -eq 1 ]]; then
                restoreAgent "$oldSrcPath" "$dstPath" "$oldDomain" "$agentName"
              fi

              return 1
            }

            removeAgent() {
              local srcPath="$1"
              local dstDir="$2"
              local newDir="$3"
              local oldDomainsDir="$4"

              local agentFile="''${srcPath##*/}"
              local agentName="''${agentFile%.plist}"
              local dstPath="$dstDir/$agentFile"
              local domainName
              local domain

              domainName="$(readAgentDomain "$oldDomainsDir" "$agentName")"
              domain="$(resolveDomain "$domainName")"

              if [[ -e "$newDir/$agentFile" ]]; then
                verboseEcho "Agent '$agentName' still exists in new generation, skipping cleanup"
                return 0
              fi

              if [[ ! -e "$dstPath" ]]; then
                verboseEcho "Agent file '$dstPath' already removed"
                return 0
              fi

              if ! cmp -s "$srcPath" "$dstPath"; then
                warnEcho "Skipping deletion of '$dstPath', since its contents have diverged"
                return 0
              fi

              # Stop and remove the agent
              bootoutAgent "$domain" "$agentName"
              case "$?" in
                0|2)
                  ;;
                *)
                  return 1
                  ;;
              esac

              verboseEcho "Removing agent file '$dstPath'"
              if run rm -f $VERBOSE_ARG "$dstPath"; then
                verboseEcho "Successfully removed agent file for '$agentName'"
              else
                warnEcho "Failed to remove agent file '$dstPath'"
                return 1
              fi

              return 0
            }

            setupLaunchAgents() {
              local oldDir newDir oldDomainsDir newDomainsDir dstDir launchdStatus

              newDir="$(readlink -m "$newGenPath/LaunchAgents")"
              newDomainsDir="$(readlink -m "$newGenPath/LaunchAgentDomains")"
              dstDir=${lib.escapeShellArg dstDir}
              launchdStatus=0

              if [[ -n "''${oldGenPath:-}" ]]; then
                oldDir="$(readlink -m "$oldGenPath/LaunchAgents")"
                if [[ ! -d "$oldDir" ]]; then
                  verboseEcho "No previous LaunchAgents directory found"
                  oldDir=""
                fi

                oldDomainsDir="$(readlink -m "$oldGenPath/LaunchAgentDomains")"
                if [[ ! -d "$oldDomainsDir" ]]; then
                  oldDomainsDir=""
                fi
              else
                oldDir=""
                oldDomainsDir=""
              fi

              verboseEcho "Setting up LaunchAgents in $dstDir"
              if [[ ! -d "$dstDir" ]] && ! run mkdir -p "$dstDir"; then
                errorEcho "Failed to create LaunchAgents directory '$dstDir'"
                return 1
              fi

              verboseEcho "Processing new/updated LaunchAgents..."
              while IFS= read -r srcPath; do
                processAgent "$srcPath" "$dstDir" "$oldDir" "$oldDomainsDir" "$newDomainsDir" \
                  || launchdStatus=1
              done < <(find -L "$newDir" -maxdepth 1 -name '*.plist' -type f)

              # Skip cleanup if there's no previous generation
              if [[ -z "$oldDir" || ! -d "$oldDir" ]]; then
                if [[ "$launchdStatus" -ne 0 ]]; then
                  errorEcho "Failed to activate one or more LaunchAgents"
                fi

                verboseEcho "LaunchAgents setup complete"
                return "$launchdStatus"
              fi

              verboseEcho "Cleaning up removed LaunchAgents..."
              while IFS= read -r srcPath; do
                removeAgent "$srcPath" "$dstDir" "$newDir" "$oldDomainsDir" \
                  || launchdStatus=1
              done < <(find -L "$oldDir" -maxdepth 1 -name '*.plist' -type f)

              if [[ "$launchdStatus" -ne 0 ]]; then
                errorEcho "Failed to activate one or more LaunchAgents"
              fi

              return "$launchdStatus"
            }

            launchdStatus=0
            setupLaunchAgents || launchdStatus=$?

            # Restore errexit
            set -e

            if [[ "$launchdStatus" -ne 0 ]]; then
              exit "$launchdStatus"
            fi
          '';
    })
  ];
}
