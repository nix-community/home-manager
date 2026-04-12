{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.retroarch;
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
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "RetroArch core";
              package = lib.mkPackageOption pkgs [ "libretro" name ] { };
            };
          }
        )
      );
      default = { };
      example = lib.literalExpression ''
        {
          mgba.enable = true;  # Uses pkgs.libretro.mgba
          snes9x = {
            enable = true;
            package = pkgs.libretro.snes9x2010;
          };
          custom-core = {
            enable = true;
            package = pkgs.callPackage ./custom-core.nix { };
          };
        }
      '';
      description = ''
        RetroArch cores to enable. You can provide custom core packages.
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
        RetroArch configuration settings.

        See <https://github.com/libretro/RetroArch/blob/master/retroarch.cfg>
        for available configuration options.
      '';
    };

    coreSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        mgba_solar_sensor_level = "0";
        snes9x_aspect = "4:3";
        snes9x_overscan = "enabled";
        snes9x_region = "auto";
      };
      description = ''
        Core-specific configuration settings.
        Keys are often prefixed with the core's name.

        See <https://docs.libretro.com/guides/core-list/>
        for available configuration options.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      attrsToText = lib.flip lib.pipe [
        (lib.mapAttrsToList (n: v: "${n} = \"${v}\""))
        lib.naturalSort
        lib.concatLines
      ];
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/RetroArch"
        else
          "${config.xdg.configHome}/retroarch";
      enabledCores = lib.filterAttrs (_: core: core.enable) cfg.cores;
    in
    lib.mkMerge [
      {
        programs.retroarch.finalPackage = (
          cfg.package.wrapper {
            inherit (cfg) settings;
            cores = lib.mapAttrsToList (_: core: core.package) enabledCores;
          }
        );
        home.packages = [ cfg.finalPackage ];
      }
      (lib.mkIf (cfg.coreSettings != { }) {
        assertions = [
          {
            assertion = cfg.settings.global_core_options or null == "true";
            message = ''
              `programs.retroarch.settings.global_core_options` must be set to "true"
              when `programs.retroarch.coreSettings` is defined.
            '';
          }
        ];
        home.file."${configDir}/retroarch-core-options.cfg".text = attrsToText cfg.coreSettings;
        programs.retroarch.settings.global_core_options = lib.mkDefault "true";
      })
    ]
  );
}
