{
  config,
  lib,
  pkgs,
  ...
}:
{
  meta.maintainers = [ lib.maintainers.HeitorAugustoLN ];

  options.wayland.desktopManager.cosmic = {
    components =
      let
        cosmicComponent = lib.types.submodule {
          options = {
            entries = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              example = lib.literalExpression ''
                {
                  autotile = true;
                  autotile_behavior = lib.ron.mkEnum { variant = "PerWorkspace"; };
                }
              '';
              description = "Configuration entries for the component.";
            };

            version = lib.mkOption {
              type = lib.types.ints.unsigned;
              example = 1;
              description = "Schema version number for the component configuration.";
            };
          };
        };
      in
      {
        config = lib.mkOption {
          type = lib.types.attrsOf cosmicComponent;
          default = { };
          example = lib.literalExpression ''
            {
              "com.system76.CosmicComp" = {
                version = 1;
                entries = {
                  autotile = true;
                  autotile_behavior = lib.ron.mkEnum { variant = "PerWorkspace"; };
                };
              };

              "com.system76.CosmicTerm" = {
                version = 1;
                entries = {
                  font_name = "JetBrains Mono";
                  font_size = 16;
                };
              };
          '';
          description = ''
            COSMIC component configurations in `$XDG_CONFIG_HOME/cosmic`.
            Uses the standard COSMIC directory structure: `{component}/v{version}/{entry}`.
          '';
        };

        data = lib.mkOption {
          type = lib.types.attrsOf cosmicComponent;
          default = { };
          description = ''
            COSMIC component data in `$XDG_DATA_HOME/cosmic`.
            Uses the standard COSMIC directory structure: `{component}/v{version}/{entry}`.
          '';
        };

        state = lib.mkOption {
          type = lib.types.attrsOf cosmicComponent;
          default = { };
          example = lib.literalExpression ''
            {
              "com.system76.CosmicBackground" = {
                version = 1;
                entries.wallpapers = [
                  (lib.ron.mkTuple [
                    "Virtual-1"
                    (lib.ron.mkEnum {
                      variant = "Path";
                      value = [ "/usr/share/backgrounds/cosmic/webb-inspired-wallpaper-system76.jpg" ];
                    })
                  ])
                ];
              };
            }
          '';
          description = ''
            COSMIC component state in `$XDG_STATE_HOME/cosmic`.
            Uses the standard COSMIC directory structure: `{component}/v{version}/{entry}`.
          '';
        };
      };

    files = {
      config = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        example = lib.literalExpression ''
          {
            "cosmic/com.system76.CosmicComp/v1/autotile" = true;
            "cosmic/com.system76.CosmicComp/v1/autotile_behavior" = lib.ron.mkEnum { variant = "PerWorkspace" };
            "cosmic/com.system76.CosmicTerm/v1/font_name" = "JetBrains Mono";
            "cosmic/com.system76.CosmicTerm/v1/font_size" = 16;
          }
        '';
        description = ''
          Direct file operations in `$XDG_CONFIG_HOME`.
          Bypasses the COSMIC component structure for custom file placement.
        '';
      };

      data = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          Direct file operations in `$XDG_DATA_HOME`.
          Bypasses the COSMIC component structure for custom file placement.
        '';
      };

      home = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        example = lib.literalExpression ''
          {
            ".config/cosmic/com.system76.CosmicComp/v1/autotile" = true;
            ".config/cosmic/com.system76.CosmicComp/v1/autotile_behavior" = lib.ron.mkEnum { variant = "PerWorkspace" };
            ".config/cosmic/com.system76.CosmicTerm/v1/font_name" = "JetBrains Mono";
            ".config/cosmic/com.system76.CosmicTerm/v1/font_size" = 16;
          }
        '';
        description = ''
          Direct file operations in the home directory.
          Bypasses both XDG directories and COSMIC component structure.
        '';
      };

      state = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        example = lib.literalExpression ''
          {
            "cosmic/com.system76.Background/v1/wallpapers" = [
              (lib.ron.mkTuple [
                "Virtual-1"
                (lib.ron.mkEnum {
                  variant = "Path";
                  value = [ "/usr/share/backgrounds/cosmic/webb-inspired-wallpaper-system76.jpg" ];
                })
              ])
            ];
          }
        '';
        description = ''
          Direct file operations in `$XDG_STATE_HOME`.
          Bypasses the COSMIC component structure for custom file placement.
        '';
      };
    };

    reset = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable COSMIC configuration files reset.

          When enabled, this option will delete any COSMIC-related files in the specified
          XDG directories that were not explicitly declared in your configuration. This
          ensures that your COSMIC desktop environment remains in a clean, known state
          as defined by your `home-manager` configuration.
        '';
      };

      directories = lib.mkOption {
        type = lib.types.nonEmptyListOf (
          lib.types.enum [
            "config"
            "data"
            "state"
            "cache"
            "runtime"
          ]
        );
        default = [
          "config"
          "state"
        ];
        example = [
          "config"
          "data"
          "state"
        ];
        description = ''
          XDG base directories to reset when `reset` is enabled.

          Available directories:
          - `config`: User configuration (`$XDG_CONFIG_HOME`)
          - `data`: Application data (`$XDG_DATA_HOME`)
          - `state`: Runtime state (`$XDG_STATE_HOME`)
          - `cache`: Cached data (`$XDG_CACHE_HOME`)
          - `runtime`: Runtime files (`$XDG_RUNTIME_DIR`)
        '';
      };

      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "com.system76.CosmicComp"
          "dev.edfloreshz.CosmicTweaks/v1"
          "com.system76.CosmicSettings/v1/active-page"
          "com.system76.CosmicTerm/v1/{font_size,font_family}"
          "com.system76.{CosmicComp,CosmicPanel.Dock}/v1"
        ];
        description = ''
          Patterns to exclude from the reset operation when `reset` is enabled.
          Supports glob patterns and brace expansion for matching files and directories.

          Use this option to preserve specific files or directories from being reset.
        '';
      };
    };
  };

  config =
    let
      cfg = config.wayland.desktopManager.cosmic;

      hasSettings =
        cfg.components.config != { }
        || cfg.components.data != { }
        || cfg.components.state != { }
        || cfg.files.config != { }
        || cfg.files.data != { }
        || cfg.files.home != { }
        || cfg.files.state != { };

      componentOperations = lib.flatten (
        lib.mapAttrsToList (
          xdg_directory: components:
          lib.mapAttrsToList (component: details: {
            inherit (details) version;
            inherit component xdg_directory;
            entries = builtins.mapAttrs (_: value: lib.ron.toRON { } value) details.entries;
            operation = "write";
          }) components
        ) cfg.components
      );

      fileOperations = lib.flatten (
        lib.mapAttrsToList (
          directory: files:
          lib.mapAttrsToList (path: value: {
            file =
              let
                prefix =
                  {
                    config = config.xdg.configHome;
                    data = config.xdg.dataHome;
                    home = config.home.homeDirectory;
                    state = config.xdg.stateHome;
                  }
                  .${directory};
              in
              "${prefix}/${path}";

            operation = "write";
            value = lib.ron.toRON { } value;
          }) files
        ) cfg.files
      );

      configurations = {
        "$schema" = "https://raw.githubusercontent.com/cosmic-utils/cosmic-ctl/refs/heads/main/schema.json";
        operations = componentOperations ++ fileOperations;
      };

      configuration = (pkgs.formats.json { }).generate "cosmic-configuration.json" configurations;
    in
    {
      home.activation =
        let
          cosmic-ctl = lib.getExe pkgs.cosmic-ext-ctl;
        in
        {
          configureCosmic = lib.mkIf hasSettings (
            lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${cosmic-ctl} apply ${configuration}"
          );

          resetCosmic = lib.mkIf cfg.reset.enable (
            let
              command = "run ${cosmic-ctl} reset --force --xdg-dirs ${builtins.concatStringsSep "," cfg.reset.directories} ${
                lib.optionalString (
                  cfg.reset.exclude != [ ]
                ) "--exclude ${builtins.concatStringsSep "," cfg.reset.exclude}"
              }";
            in
            if hasSettings then
              lib.hm.dag.entryBefore [ "configureCosmic" ] command
            else
              lib.hm.dag.entryAfter [ "writeBoundary" ] command
          );
        };
    };
}
