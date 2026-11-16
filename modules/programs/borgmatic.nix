{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.borgmatic;

  yamlFormat = pkgs.formats.yaml { };

  mkNullableOption =
    args:
    lib.mkOption (
      args
      // {
        type = lib.types.nullOr args.type;
        default = null;
      }
    );

  cleanRepositories =
    repos:
    map (
      repo:
      if builtins.isString repo then
        {
          path = repo;
        }
      else
        removeNullValues repo
    ) repos;

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
        type = types.enum [
          "repository"
          "archives"
          "data"
          "extract"
        ];
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

  repositoriesOption = mkOption {
    type = types.nullOr (types.listOf (types.either types.str repositoryOption));
    default = [ ];
    apply = lib.mapNullable cleanRepositories;
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
    description = "List of local or remote repositories with paths and optional labels.";
  };

  checksOption = mkOption {
    type = types.listOf consistencyCheckModule;
    default = [ ];
    description = "Consistency checks to run";
    example = literalExpression ''
      [
        { name = "repository"; frequency = "2 weeks"; }
        { name = "archives"; frequency = "4 weeks"; }
        { name = "data"; frequency = "6 weeks"; }
        { name = "extract"; frequency = "6 weeks"; }
      ]
    '';
  };

  configModule = types.submodule (
    { config, options, ... }:
    let
      overlays =
        map
          (
            section:
            lib.hm.deprecations.mkSettingsOverlay {
              inherit options;
              from = [
                section
                "extraConfig"
              ];
              to = [ "settings" ];
            }
          )
          [
            "location"
            "storage"
            "retention"
            "consistency"
            "output"
            "hooks"
          ];
      overlayKeys = lib.concatMap (overlay: overlay.keys) overlays;
    in
    {
      imports =
        lib.hm.deprecations.mkSettingsRenamedOptionModules [ ] [ "settings" ]
          {
            priority = 1400;
            preserveOrder = true;
          }
          [
            {
              old = [
                "location"
                "sourceDirectories"
              ];
              new = "source_directories";
              fallback = null;
              shadowed = lib.elem "source_directories" overlayKeys;
            }
            {
              old = [
                "location"
                "patterns"
              ];
              new = "patterns";
              fallback = null;
              shadowed = lib.elem "patterns" overlayKeys;
            }
            {
              old = [
                "storage"
                "encryptionPasscommand"
              ];
              new = "encryption_passcommand";
              fallback = null;
              shadowed = lib.elem "encryption_passcommand" overlayKeys;
            }
          ]
        ++
          lib.hm.deprecations.mkSettingsRenamedOptionModules [ "retention" ] [ "settings" ]
            { priority = 1400; }
            (
              map
                (name: {
                  old = name;
                  new = lib.hm.strings.toSnakeCase name;
                  fallback = null;
                  shadowed = lib.elem (lib.hm.strings.toSnakeCase name) overlayKeys;
                })
                [
                  "keepWithin"
                  "keepSecondly"
                  "keepMinutely"
                  "keepHourly"
                  "keepDaily"
                  "keepWeekly"
                  "keepMonthly"
                  "keepYearly"
                ]
            )
        ++ [
          (lib.hm.deprecations.mkSettingsChangedOptionModule {
            from = [
              "location"
              "repositories"
            ];
            to = [ "settings" ];
            key = "repositories";
            priority = 1400;
            applyDefault = value: value != [ ];
            oldOption = repositoriesOption;
            shadowed = lib.elem "repositories" overlayKeys;
            convert = lib.id;
          })
          (lib.hm.deprecations.mkSettingsChangedOptionModule {
            from = [
              "consistency"
              "checks"
            ];
            to = [ "settings" ];
            key = "checks";
            priority = 1400;
            applyDefault = value: value != [ ];
            oldOption = checksOption;
            shadowed = lib.elem "checks" overlayKeys;
            convert = map removeNullValues;
          })
        ]
        ++ map (overlay: overlay.module) overlays;

      options = {
        warnings = mkOption {
          type = types.listOf types.str;
          default = [ ];
          internal = true;
          visible = false;
        };

        settings = mkOption {
          type = types.submodule {
            freeformType = yamlFormat.type;
            config = {
              # Legacy backups always wrote an empty checks list, even if checks was unset.
              checks = lib.mkIf (config.warnings != [ ]) (lib.mkOptionDefault [ ]);
              exclude_from = lib.mkIf config.location.excludeHomeManagerSymlinks (
                lib.mkAfter [ (toString hmExcludeFile) ]
              );
            };
          };
          default = { };
          description = ''
            Native borgmatic YAML settings for this backup. Deprecated section
            options are forwarded into settings and emit migration warnings.
            Define new configuration here to avoid the legacy aliases.

            Home Manager exclusions append to `exclude_from`; use `lib.mkForce`
            to replace the list.

            Top-level null values are omitted, so enable hooks that take no
            options, such as `zfs`, `btrfs`, or `lvm`, with `{ }` instead of
            `null`. Deprecated aliases define settings at normal priority, so
            a `lib.mkDefault` on the whole settings value is ignored while any
            alias is set; apply it to individual keys instead.

            See <https://github.com/borgmatic-collective/borgmatic/blob/main/borgmatic/config/schema.yaml>
            for the available settings.
          '';
        };

        location.excludeHomeManagerSymlinks = mkOption {
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
      };
    }
  );

  removeNullValues = attrSet: lib.filterAttrs (_key: value: value != null) attrSet;

  hmFiles = builtins.attrValues config.home.file;
  hmSymlinks = (lib.filter (file: !file.recursive) hmFiles);
  hmExcludePattern = file: ''
    ${config.home.homeDirectory}/${file.target}
  '';
  hmExcludePatterns = lib.concatMapStrings hmExcludePattern hmSymlinks;
  hmExcludeFile = pkgs.writeText "hm-symlinks.txt" hmExcludePatterns;
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options = {
    programs.borgmatic = {
      enable = lib.mkEnableOption "Borgmatic";

      package = lib.mkPackageOption pkgs "borgmatic" { nullable = true; };

      backups = mkOption {
        type = types.attrsOf configModule;
        description = ''
          Borgmatic allows for several named backup configurations,
          each with its own source directories and repositories.
        '';
        example = literalExpression ''
          {
            personal.settings = {
              source_directories = [ "/home/me/personal" ];
              repositories = [ { path = "ssh://myuser@myserver.com/./personal-repo"; } ];
            };
            work.settings = {
              source_directories = [ "/home/me/work" ];
              repositories = [ { path = "ssh://myuser@myserver.com/./work-repo"; } ];
            };
          };
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.concatLists (
      lib.mapAttrsToList (
        name: backup:
        map (warning: "Borgmatic backup `programs.borgmatic.backups.${name}`: ${warning}") backup.warnings
      ) cfg.backups
    );

    assertions = lib.mapAttrsToList (backup: opts: {
      assertion = (opts.settings.repositories or null) != null;
      message = ''
        Borgmatic backup configuration "${backup}" must specify 'settings.repositories' (or the deprecated 'location.repositories').
      '';
    }) cfg.backups;

    xdg.configFile =
      with lib.attrsets;
      mapAttrs' (
        configName: config:
        nameValuePair ("borgmatic.d/" + configName + ".yaml") {
          text = lib.generators.toYAML { } (removeNullValues config.settings);
        }
      ) cfg.backups;

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
  };
}
