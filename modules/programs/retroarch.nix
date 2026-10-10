{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.retroarch;

  enabledCores = lib.filterAttrs (_: core: core.enable) cfg.cores;

  toKeyValue = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = v: "\"${v}\""; } " = ";
  };

  configDir =
    if (pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable) then
      "Library/Application Support/RetroArch"
    else
      "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/retroarch";

  # RetroArch reads directory settings at runtime, so they must be absolute.
  absoluteConfigDir = "${config.home.homeDirectory}/${configDir}";

  mkKeyValueOption =
    description:
    lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      inherit description;
    };

  overrideOptions = {
    options = {
      settingsOverrides = mkKeyValueOption ''
        Overrides of global `retroarch.cfg` settings, written as a `.cfg`
        override file. Only the settings that differ from the global
        configuration need to be specified.

        See <https://docs.libretro.com/guides/overrides/> for details.
      '';

      inputRemaps = mkKeyValueOption ''
        Input remappings, written as a `.rmp` remap file under the
        `config/remaps` directory. These override the input bindings from
        `retroarch.cfg` when the corresponding content is loaded.

        See <https://docs.libretro.com/guides/overrides/> for details.
      '';
    };
  };

  coreType = lib.types.submodule (
    { name, ... }:
    {
      imports = [ overrideOptions ];
      options = {
        enable = lib.mkEnableOption "RetroArch core";

        package = lib.mkPackageOption pkgs [ "libretro" name ] { };

        options = mkKeyValueOption ''
          Core options that configure this core's behavior.

          These are merged with the options of all other cores into the
          global `retroarch-core-options.cfg`. Keys are typically prefixed
          with the core's name to avoid collisions.

          These are the settings found under `Quick Menu -> Options`.

          See <https://docs.libretro.com/guides/core-list/> for available
          options.
        '';

        perContentDirectory = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule overrideOptions);
          default = { };
          description = ''
            Overrides applied when loading content from a particular directory.
            The attribute name is the content directory name. These take
            precedence over the core-level overrides.

            See <https://docs.libretro.com/guides/overrides/> for details.
          '';
        };

        perGame = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              imports = [ overrideOptions ];
              options = {
                options = mkKeyValueOption ''
                  Game-specific core options, written as a `.opt` file. These
                  take precedence over the core's `options`.

                  See <https://docs.libretro.com/guides/overrides/> for
                  details.
                '';
              };
            }
          );
          default = { };
          description = ''
            Overrides applied when loading a particular game. The attribute
            name is the game (content) name. These take precedence over the
            per-content-directory overrides.

            See <https://docs.libretro.com/guides/overrides/> for details.
          '';
        };
      };
    }
  );

  mkFileIfPresent =
    path: attrs:
    lib.optionalAttrs (attrs != { }) {
      "${configDir}/${path}".text = toKeyValue attrs;
    };
in
{
  meta.maintainers = [
    lib.hm.maintainers.jtrrll
  ];

  options.programs.retroarch = {
    enable = lib.mkEnableOption "RetroArch";

    package = lib.mkPackageOption pkgs "retroarch" {
      default = "retroarch-bare";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = ''
        Resulting RetroArch package.
      '';
    };

    cores = lib.mkOption {
      type = lib.types.attrsOf coreType;
      default = { };
      example = lib.literalExpression ''
        {
          mGBA.enable = true;  # Uses pkgs.libretro.mgba
          "Snes9x - Current" = {
            enable = true;
            package = pkgs.libretro.snes9x;
            options = {
              snes9x_aspect = "4:3";
              snes9x_region = "auto";
            };
          };
          custom-core = {
            enable = true;
            package = pkgs.callPackage ./custom-core.nix { };
          };
        }
      '';
      description = ''
        RetroArch cores to enable. You can provide custom core packages.

        The attribute name must match the core's directory name as reported by
        RetroArch (its `library_name`), since it is used to locate the
        per-core options and override files under `config/<name>`.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        input_max_users = "4";
        menu_scale_factor = "0.950000";
        netplay_nickname = "username";
        video_driver = "vulkan";
        video_fullscreen = "true";
      };
      description = ''
        RetroArch configuration settings written to `retroarch.cfg`.

        Because the configuration file is managed declaratively, RetroArch is
        configured to not overwrite it on exit. Any changes made through the
        RetroArch UI will therefore not be persisted.

        See <https://github.com/libretro/RetroArch/blob/master/retroarch.cfg>
        for available configuration options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.retroarch = {
      settings = {
        config_save_on_exit = lib.mkDefault "false";
        game_specific_options = lib.mkDefault "true";
        global_core_options = lib.mkDefault "true";
        remap_save_on_exit = lib.mkDefault "false";
        rgui_config_directory = lib.mkDefault "${absoluteConfigDir}/config";
        input_remapping_directory = lib.mkDefault "${absoluteConfigDir}/config/remaps";
      };

      finalPackage = cfg.package.wrapper {
        cores = lib.mapAttrsToList (_: core: core.package) enabledCores;
      };
    };

    home = {
      packages = [ cfg.finalPackage ];

      file = {
        "${configDir}/retroarch.cfg".text = toKeyValue cfg.settings;
        "${configDir}/retroarch-core-options.cfg".text = toKeyValue (
          lib.concatMapAttrs (_: core: core.options) enabledCores
        );
      }
      // lib.concatMapAttrs (
        name: core:
        mkFileIfPresent "config/${name}/${name}.cfg" core.settingsOverrides
        // mkFileIfPresent "config/remaps/${name}/${name}.rmp" core.inputRemaps
        // lib.concatMapAttrs (
          contentDir: scope:
          mkFileIfPresent "config/${name}/${contentDir}.cfg" scope.settingsOverrides
          // mkFileIfPresent "config/remaps/${name}/${contentDir}.rmp" scope.inputRemaps
        ) core.perContentDirectory
        // lib.concatMapAttrs (
          game: scope:
          mkFileIfPresent "config/${name}/${game}.opt" scope.options
          // mkFileIfPresent "config/${name}/${game}.cfg" scope.settingsOverrides
          // mkFileIfPresent "config/remaps/${name}/${game}.rmp" scope.inputRemaps
        ) core.perGame
      ) enabledCores;
    };
  };
}
