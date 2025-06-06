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

    package = lib.mkPackageOption pkgs "mc" { nullable = true; }};

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra contents for ~/.config/mc/ini";
    };

    keymapConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra contents for ~/.config/mc/mc.keymap";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "mc/ini".text = cfg.extraConfig;
      "mc/mc.keymap".text = cfg.keymapConfig;
    };
  };
}
