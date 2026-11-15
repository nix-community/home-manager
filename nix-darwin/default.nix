{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.home-manager;

  # Agents that must run without a login session. launchd only loads
  # ~/Library/LaunchAgents at graphical login, so these need an explicit
  # bootstrap after every boot.
  userDomainAgents =
    usercfg:
    lib.filter (agent: agent.enable && agent.domain == "user") (lib.attrValues usercfg.launchd.agents);

  # Bootstraps the user's user-domain agents into its per-user launchd
  # domain. The domain itself is created on demand by launchctl, so this
  # also works on machines that never had a login session.
  primerScript =
    usercfg:
    let
      plists = map (agent: {
        label = agent.config.Label;
        path = "${usercfg.home.homeDirectory}/Library/LaunchAgents/${agent.config.Label}.plist";
      }) (userDomainAgents usercfg);
    in
    ''
      uid="$(/usr/bin/id -u ${lib.escapeShellArg usercfg.home.username})"

      ${lib.concatMapStringsSep "\n" (plist: ''
        if /bin/launchctl print "user/$uid/${plist.label}" >/dev/null 2>&1; then
          echo "already loaded: ${plist.label}"
        elif bootstrap_output="$(/bin/launchctl bootstrap "user/$uid" ${lib.escapeShellArg plist.path} 2>&1)"; then
          echo "bootstrapped: ${plist.label}"
        elif /bin/launchctl print "user/$uid/${plist.label}" >/dev/null 2>&1; then
          # Loaded concurrently, for example by Home Manager's own activation
          # while this daemon was being installed.
          echo "already loaded: ${plist.label}"
        else
          echo "failed to bootstrap: ${plist.label}: $bootstrap_output" >&2
        fi
      '') plists}
    '';

in
{
  imports = [ ../nixos/common.nix ];

  config = lib.mkMerge [
    { home-manager.extraSpecialArgs.darwinConfig = config; }
    (lib.mkIf (cfg.users != { }) {
      launchd.daemons =
        lib.mapAttrs'
          (
            username: usercfg:
            lib.nameValuePair "org.nix-community.home.launchd-primer.${username}" {
              script = primerScript usercfg;
              serviceConfig = {
                Label = "org.nix-community.home.launchd-primer.${username}";
                KeepAlive = false;
                RunAtLoad = true;
                StandardOutPath = "/var/log/org.nix-community.home.launchd-primer.${username}.log";
                StandardErrorPath = "/var/log/org.nix-community.home.launchd-primer.${username}.log";
              };
            }
          )
          (lib.filterAttrs (_: usercfg: usercfg.launchd.enable && userDomainAgents usercfg != [ ]) cfg.users);

      system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _username: usercfg:
          let
            driverVersion = if cfg.enableLegacyProfileManagement then "0" else "1";
          in
          ''
            echo Activating home-manager configuration for ${usercfg.home.username} >&2
            hmDryRunArgs=()
            hmParentArgs="$(ps -p "$PPID" -ww -o args= || true)"
            if [[ -v DRY_RUN || "$hmParentArgs" == *" --dry-run"* ]]; then
              hmDryRunArgs=(env DRY_RUN=1)
            fi
            launchctl asuser "$(id -u ${usercfg.home.username})" sudo -u ${usercfg.home.username} --set-home "''${hmDryRunArgs[@]}" ${pkgs.writeShellScript "activation-${usercfg.home.username}" ''
              ${lib.optionalString (
                cfg.backupFileExtension != null
              ) "export HOME_MANAGER_BACKUP_EXT=${lib.escapeShellArg cfg.backupFileExtension}"}
              ${lib.optionalString (
                cfg.backupCommand != null
              ) "export HOME_MANAGER_BACKUP_COMMAND=${lib.escapeShellArg cfg.backupCommand}"}
              ${lib.optionalString cfg.overwriteBackup "export HOME_MANAGER_BACKUP_OVERWRITE=1"}
              ${lib.optionalString cfg.verbose "export VERBOSE=1"}
              exec ${usercfg.home.activationPackage}/activate --driver-version ${driverVersion} >&2
            ''}
          ''
        ) cfg.users
      );
    })
  ];
}
