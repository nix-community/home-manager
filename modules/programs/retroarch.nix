{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.retroarch;

  enabledCores = lib.filterAttrs (_: core: core.enable) cfg.cores;
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
  };

  config = lib.mkIf cfg.enable {
    programs.retroarch.finalPackage = (
      cfg.package.wrapper {
        inherit (cfg) settings;
        cores = lib.mapAttrsToList (_: core: core.package) enabledCores;
      }
    );
    home.packages = [ cfg.finalPackage ];
  };
}
