{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.borgmatic;

  yamlFormat = pkgs.formats.yaml { };

  mkNullableOption = args:
    lib.mkOption (args // {
      type = lib.types.nullOr args.type;
      default = null;
    });

  cleanRepositories = repos:
    map (repo:
      if builtins.isString repo then {
        path = repo;
      } else
        removeNullValues repo) repos;

  mkRetentionOption = frequency:
    mkNullableOption {
      type = types.int;
      description =
        "Number of ${frequency} archives to keep. Use -1 for no limit.";
      example = 3;
    };

  extraConfigOption = mkOption {
    type = yamlFormat.type;
    default = { };
    description = "Extra settings.";
  };

  repositoryOption = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        example = "ssh://myuser@myrepo.myserver.com/./repo";
        description = "Path of the repository.";
      };

      label = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "remote";
        description = ''
          Short text describing the repository. Can be used with the
          `--repository` flag to select a repository.
        '';
      };
    };
  };

  consistencyCheckModule = types.submodule {
    options = {
      name = mkOption {
        type = types.enum [ "repository" "archives" "data" "extract" ];
        description = "Name of consistency check to run.";
        example = "repository";
      };

      frequency = mkNullableOption {
        type = types.strMatching "([[:digit:]]+ .*)|always";
        description = "Frequency of this type of check";
        example = "2 weeks";
      };
    };
  };

  configModule = types.submodule ({ config, ... }: {
    config.location.extraConfig.exclude_from =
      mkIf config.location.excludeHomeManagerSymlinks
      (mkAfter [ (toString hmExcludeFile) ]);
    options = {
      location = {
        sourceDirectories = mkNullableOption {
          type = types.listOf types.str;
          default = null;
          description = ''
            Directories to backup.

            Mutually exclusive with [](#opt-programs.borgmatic.backups._name_.location.patterns).
          '';
          example = literalExpression "[config.home.homeDirectory]";
        };

        patterns = mkNullableOption {
          type = types.listOf types.str;
          default = null;
          description = ''
            Patterns to include/exclude.

            See the output of `borg help patterns` for the syntax. Pattern paths
            are relative to `/` even when a different recursion root is set.

            Mutually exclusive with [](#opt-programs.borgmatic.backups._name_.location.sourceDirectories).
          '';
          example = literalExpression ''
            [
              "R /home/user"
              "- home/user/.cache"
              "- home/user/Downloads"
              "+ home/user/Videos/Important Video"
              "- home/user/Videos"
            ]
          '';
        };

        repositories = mkOption {
          type = types.listOf (types.either types.str repositoryOption);
          apply = cleanRepositories;
          example = literalExpression ''
            [
              {
                "path" = "ssh://myuser@myrepo.myserver.com/./repo";
                "label" = "server";
              }
              {
                "path" = "/var/lib/backups/local.borg";
                "label" = "local";
              }
            ]
          '';
          description = ''
            List of local or remote repositories with paths and optional labels.
          '';
        };

        excludeHomeManagerSymlinks = mkOption {
          type = types.bool;
          description = ''
            Whether to exclude Home Manager generated symbolic links from
            the backups. This facilitates restoring the whole home
            directory when the Nix store doesn't contain the latest
            Home Manager generation.
          '';
          default = false;
          example = true;
        };

        extraConfig = extraConfigOption;
      };

      storage = {
        encryptionPasscommand = mkNullableOption {
          type = types.str;
          description = "Command writing the passphrase to standard output.";
          example =
            literalExpression ''"''${pkgs.password-store}/bin/pass borg-repo"'';
        };
        extraConfig = extraConfigOption;
      };

      retention = {
        keepWithin = mkNullableOption {
          type = types.strMatching "[[:digit:]]+[Hdwmy]";
          description = "Keep all archives within this time interval.";
          example = "2d";
        };

        keepSecondly = mkRetentionOption "secondly";
        keepMinutely = mkRetentionOption "minutely";
        keepHourly = mkRetentionOption "hourly";
        keepDaily = mkRetentionOption "daily";
        keepWeekly = mkRetentionOption "weekly";
        keepMonthly = mkRetentionOption "monthly";
        keepYearly = mkRetentionOption "yearly";

        extraConfig = extraConfigOption;
      };

      consistency = {
        checks = mkOption {
          type = types.listOf consistencyCheckModule;
          default = [ ];
          description = "Consistency checks to run";
          example = literalExpression ''
            [
              {
                name = "repository";
                frequency = "2 weeks";
              }
              {
                name = "archives";
                frequency = "4 weeks";
              }
              {
                name = "data";
                frequency = "6 weeks";
              }
              {
                name = "extract";
                frequency = "6 weeks";
              }
            ];
          '';
        };

        extraConfig = extraConfigOption;
      };

      output = { extraConfig = extraConfigOption; };

      hooks = { extraConfig = extraConfigOption; };
    };
  });

  removeNullValues = attrSet: filterAttrs (key: value: value != null) attrSet;

  hmFiles = builtins.attrValues config.home.file;
  hmSymlinks = (lib.filter (file: !file.recursive) hmFiles);
  hmExcludePattern = file: ''
    ${config.home.homeDirectory}/${file.target}
  '';
  hmExcludePatterns = lib.concatMapStrings hmExcludePattern hmSymlinks;
  hmExcludeFile = pkgs.writeText "hm-symlinks.txt" hmExcludePatterns;

  writeConfig = config:
    generators.toYAML { } (removeNullValues ({
      source_directories = config.location.sourceDirectories;
      patterns = config.location.patterns;
      repositories = config.location.repositories;
      encryption_passcommand = config.storage.encryptionPasscommand;
      keep_within = config.retention.keepWithin;
      keep_secondly = config.retention.keepSecondly;
      keep_minutely = config.retention.keepMinutely;
      keep_hourly = config.retention.keepHourly;
      keep_daily = config.retention.keepDaily;
      keep_weekly = config.retention.keepWeekly;
      keep_monthly = config.retention.keepMonthly;
      keep_yearly = config.retention.keepYearly;
      checks = config.consistency.checks;
    } // config.location.extraConfig // config.storage.extraConfig
      // config.retention.extraConfig // config.consistency.extraConfig
      // config.output.extraConfig // config.hooks.extraConfig));
in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options = {
    programs.borgmatic = {
      enable = mkEnableOption "Borgmatic";

      package = mkPackageOption pkgs "borgmatic" { };

      backups = mkOption {
        type = types.attrsOf configModule;
        description = ''
          Borgmatic allows for several named backup configurations,
          each with its own source directories and repositories.
        '';
        example = literalExpression ''
          {
            personal = {
              location = {
                sourceDirectories = [ "/home/me/personal" ];
                repositories = [ "ssh://myuser@myserver.com/./personal-repo" ];
              };
            };
            work = {
              location = {
                sourceDirectories = [ "/home/me/work" ];
                repositories = [ "ssh://myuser@myserver.com/./work-repo" ];
              };
            };
          };
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = (mapAttrsToList (backup: opts: {
      assertion = opts.location.sourceDirectories == null
        || opts.location.patterns == null;
      message = ''
        Borgmatic backup configuration "${backup}" cannot specify both 'location.sourceDirectories' and 'location.patterns'.
      '';
    }) cfg.backups) ++ (mapAttrsToList (backup: opts: {
      assertion = !(opts.location.sourceDirectories == null
        && opts.location.patterns == null);
      message = ''
        Borgmatic backup configuration "${backup}" must specify one of 'location.sourceDirectories' or 'location.patterns'.
      '';
    }) cfg.backups);

    xdg.configFile = with lib.attrsets;
      mapAttrs' (configName: config:
        nameValuePair ("borgmatic.d/" + configName + ".yaml") {
          text = writeConfig config;
        }) cfg.backups;

    home.packages = [ cfg.package ];
  };
}
