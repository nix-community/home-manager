{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.git-sync;

  mkUnit = name: repo: {
    Unit.Description = "Git Sync ${name}";

    Install.WantedBy = [ "default.target" ];

    Service = {
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [ openssh git ])}"
        "GIT_SYNC_DIRECTORY=${repo.path}"
        "GIT_SYNC_COMMAND=${cfg.package}/bin/git-sync"
        "GIT_SYNC_REPOSITORY=${repo.uri}"
        "GIT_SYNC_INTERVAL=${toString repo.interval}"
      ];
      ExecStart = "${cfg.package}/bin/git-sync-on-inotify";
      Restart = "on-abort";
    };
  };

  mkAgent = name: repo: {
    enable = true;
    config = {
      StartInterval = repo.interval;
      ProcessType = "Background";
      WorkingDirectory = "${repo.path}";
      WatchPaths = [ "${repo.path}" ];
      ProgramArguments = [ "${cfg.package}/bin/git-sync" ];
    };
  };

  mkService = if pkgs.stdenv.isLinux then mkUnit else mkAgent;
  services = mapAttrs' (name: repo: {
    name = "git-sync-${name}";
    value = mkService name repo;
  }) cfg.repositories;

  repositoryType = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        internal = true;
        default = name;
        type = types.str;
        description = "The name that should be given to this unit.";
      };

      path = mkOption {
        type = types.path;
        description = "The path at which to sync the repository";
      };

      uri = mkOption {
        type = types.str;
        example = "git+ssh://user@example.com:/~[user]/path/to/repo.git";
        description = ''
          The URI of the remote to be synchronized. This is only used in the
          event that the directory does not already exist. See
          <https://git-scm.com/docs/git-clone#_git_urls>
          for the supported URIs.

          This option is not supported on Darwin.
        '';
      };

      interval = mkOption {
        type = types.int;
        default = 500;
        description = ''
          The interval, specified in seconds, at which the synchronization will
          be triggered even without filesystem changes.
        '';
      };
    };
  });

in {
  meta.maintainers =
    [ maintainers.imalison maintainers.cab404 maintainers.ryane ];

  options = {
    services.git-sync = {
      enable = mkEnableOption "git-sync services";

      package = mkOption {
        type = types.package;
        default = pkgs.git-sync;
        defaultText = literalExpression "pkgs.git-sync";
        description = ''
          Package containing the {command}`git-sync` program.
        '';
      };

      repositories = mkOption {
        type = with types; attrsOf repositoryType;
        description = ''
          The repositories that should be synchronized.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isLinux { systemd.user.services = services; })
    (mkIf pkgs.stdenv.isDarwin { launchd.agents = services; })
  ]);

}
