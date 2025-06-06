{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.mc;
in
{
  options.programs.mc = {
    enable = mkEnableOption "Midnight Commander";

    package = lib.mkPackageOption pkgs "mc" { nullable = true; };

    settings = lib.mkOption {
      type = (pkgs.formats.ini { }).type;
      default = { };
      description = "Settings for `Midnight Commander`.";
    };

    keymapSettings = lib.mkOption {
      type = (pkgs.formats.ini { }).type;
      default = { };
      description = "Settings for ~/.config/mc/mc.keymap";
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "mc/ini" = lib.mkIf (cfg.settings != { }) {
        text = lib.generators.toINI { } cfg.settings;
      };
      "mc/mc.keymap" = lib.mkIf (cfg.keymapSettings != { }) {
        text = lib.generators.toINI { } cfg.keymapSettings;
      };
    };
  };
}
