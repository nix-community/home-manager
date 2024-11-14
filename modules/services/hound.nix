{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.hound;

  jsonFormat = pkgs.formats.json { };

  configFile = jsonFormat.generate "hound-config.json" {
    max-concurrent-indexers = cfg.maxConcurrentIndexers;
    dbpath = cfg.databasePath;
    repos = cfg.repositories;
    health-check-url = "/healthz";
  };

  houndOptions = [ "--addr ${cfg.listenAddress}" "--conf ${configFile}" ];

in {
  meta.maintainers = [ maintainers.adisbladis ];

  options.services.hound = {
    enable = mkEnableOption "hound";

    maxConcurrentIndexers = mkOption {
      type = types.ints.positive;
      default = 2;
      description = "Limit the amount of concurrent indexers.";
    };

    databasePath = mkOption {
      type = types.path;
      default = "${config.xdg.dataHome}/hound";
      defaultText = "$XDG_DATA_HOME/hound";
      description = "The Hound database path.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "localhost:6080";
      description = "Listen address of the Hound daemon.";
    };

    repositories = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          SomeGitRepo = {
            url = "https://www.github.com/YourOrganization/RepoOne.git";
            ms-between-poll = 10000;
            exclude-dot-files = true;
          };
        }
      '';
      description = "The repository configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.hound" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ pkgs.hound ];

    systemd.user.services.hound = {
      Unit = { Description = "Hound source code search engine"; };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        Environment = [ "PATH=${makeBinPath [ pkgs.mercurial pkgs.git ]}" ];
        ExecStart =
          "${pkgs.hound}/bin/houndd ${concatStringsSep " " houndOptions}";
      };
    };
  };
}
