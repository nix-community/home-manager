{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.lutris;

  cemuConf = ''
    cemu:
      runner_executable: ${lib.getExe pkgs.cemu}
  '';
  dolphinConf = ''
    dolphin:
      runner_executable: ${lib.getExe cfg.runners.dolphin.package}
  '';
  duckstationConf = ''
    duckstation:
      runner_executable: ${lib.getExe pkgs.duckstation}
  '';
  pcsx2Conf = ''
    pcsx2:
      runner_executable: ${lib.getExe pkgs.pcsx2}
      nogui: ${boolToString cfg.runners.pcsx2.noGui}
      visible_in_side_panel: ${boolToString cfg.runners.pcsx2.visible}
      full_boot: ${boolToString cfg.runners.pcsx2.fullBoot}
      fullscreen: ${boolToString cfg.runners.pcsx2.fullscreen}
  '';
  ppssppConf = ''
    ppsspp:
      runner_executable: ${lib.getExe cfg.runners.ppsspp.package}
  '';
  rpcs3Conf = ''
    rpcs3:
      runner_executable: ${lib.getExe pkgs.rpcs3}
      nogui: ${boolToString cfg.runners.rpcs3.noGui}
      visible_in_side_panel: ${boolToString cfg.runners.rpcs3.visible}
  '';

in {
  meta.maintainers = [ maintainers.rapiteanu ];

  options = {
    programs.lutris = {
      enable = mkEnableOption "Open Source gaming platform for GNU/Linux";

      package = mkOption {
        type = types.package;
        default = pkgs.lutris;
        defaultText = literalExpression "pkgs.lutris";
        description = "The Lutris package to use.";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example =
          literalExpression "[ pkgs.wineWowPackages.staging pkgs.winetricks ]";
        description = "Packages that should be available to Lutris.";
      };

      runners = {
        cemu.enable = mkEnableOption "cemu";

        dolphin = {
          enable = mkEnableOption "dolphin-emu";
          package = mkOption {
            type = types.package;
            default = pkgs.dolphin-emu;
            defaultText = literalExpression "pkgs.dolphin-emu";
            description = "The Lutris Dolphin Emulator package to use.";
          };
        };

        duckstation.enable = mkEnableOption "duckstation";

        pcsx2 = {
          enable = mkEnableOption "pcsx2";
          noGui = mkOption {
            type = types.bool;
            default = false;
            description = "Run the PCSX2 application without a GUI.";
          };
          visible = mkOption {
            type = types.bool;
            default = true;
            description = "Set the PCSX2 visiblity in the side panel.";
          };
          fullBoot = mkOption {
            type = types.bool;
            default = false;
            description = "Don't skip the BIOS handover.";
          };
          fullscreen = mkOption {
            type = types.bool;
            default = false;
            description = "Run the RPCS3 application in fullscreen.";
          };
        };

        ppsspp = {
          enable = mkEnableOption "ppsspp";
          package = mkOption {
            type = types.package;
            default = pkgs.ppsspp;
            defaultText = literalExpression "pkgs.ppsspp";
            description = "The Lutris PPSSPP package to use.";
          };
        };

        rpcs3 = {
          enable = mkEnableOption "rpcs3";
          noGui = mkOption {
            type = types.bool;
            default = false;
            description = "Run the RPCS3 application without a GUI.";
          };
          visible = mkOption {
            type = types.bool;
            default = true;
            description = "Set the RPCS3 visiblity in the side panel.";
          };
        };
      };

    };
  };

  config = mkIf cfg.enable {
    home.packages =
      [ (cfg.package.override { extraPkgs = pkgs: cfg.extraPackages; }) ]
      ++ optional cfg.runners.cemu.enable pkgs.cemu
      ++ optional cfg.runners.dolphin.enable cfg.runners.dolphin.package
      ++ optional cfg.runners.duckstation.enable pkgs.duckstation
      ++ optional cfg.runners.pcsx2.enable pkgs.pcsx2
      ++ optional cfg.runners.ppsspp.enable cfg.runners.ppsspp.package
      ++ optional cfg.runners.rpcs3.enable pkgs.rpcs3;

    xdg.dataFile = {
      "lutris/runners/cemu.yml" =
        mkIf (cfg.runners.cemu.enable) { text = cemuConf; };
      "lutris/runners/dolphin.yml" =
        mkIf (cfg.runners.dolphin.enable) { text = dolphinConf; };
      "lutris/runners/duckstation.yml" =
        mkIf (cfg.runners.duckstation.enable) { text = duckstationConf; };
      "lutris/runners/pcsx2.yml" =
        mkIf (cfg.runners.pcsx2.enable) { text = pcsx2Conf; };
      "lutris/runners/ppsspp.yml" =
        mkIf (cfg.runners.ppsspp.enable) { text = ppssppConf; };
      "lutris/runners/rpcs3.yml" =
        mkIf (cfg.runners.rpcs3.enable) { text = rpcs3Conf; };
    };
  };
}
