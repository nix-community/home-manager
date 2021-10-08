{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.git-sync;

  mkUnit = name: repo: {
    Unit.Description = "Git Sync ${name}";

    Install.WantedBy = [ "default.target" ];

    Service = {
      Environment = [
        "GIT_SYNC_DIRECTORY=${repo.path}"
        "GIT_SYNC_COMMAND=${cfg.package}/bin/git-sync"
        "GIT_SYNC_REPOSITORY=${repo.uri}"
        "GIT_SYNC_INTERVAL=${toString repo.interval}"
      ];
      ExecStart = "${cfg.package}/bin/git-sync-on-inotify";
      Restart = "on-abort";
    };
  };

  services = mapAttrs' (name: repo: {
    name = "git-sync-${name}";
    value = mkUnit name repo;
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
          <link xlink:href="https://git-scm.com/docs/git-clone#_git_urls"/>
          for the supported URIs.
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
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.git-sync = {
      enable = mkEnableOption "git-sync services";

      package = mkOption {
        type = types.package;
        default = pkgs.git-sync;
        defaultText = literalExpression "pkgs.git-sync";
        description = ''
          Package containing the <command>git-sync</command> program.
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

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.git-sync" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services = services;
  };
}
