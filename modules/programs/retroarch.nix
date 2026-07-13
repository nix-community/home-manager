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
    programs.retroarch.settings.config_save_on_exit = lib.mkDefault "false";

    programs.retroarch.finalPackage = cfg.package.wrapper {
      cores = lib.mapAttrsToList (_: core: core.package) enabledCores;
    };

    home.packages = [ cfg.finalPackage ];

    home.file."${configDir}/retroarch.cfg".text = toKeyValue cfg.settings;
  };
}
