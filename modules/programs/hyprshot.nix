{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.hyprshot;
in
{
  meta.maintainers = with lib.hm.maintainers; [
    joker9944
  ];

  options.programs.hyprshot = {
    enable = lib.mkEnableOption "Hyprshot the Hyprland screenshot utility";
    package = lib.mkPackageOption pkgs "hyprshot" { nullable = true; };
    saveLocation = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "$HOME/Pictures/Screenshots";
      description = ''
        Set the `$HYPRSHOT_DIR` environment variable to the given location.

        Hypershot will save screenshots to the first expression that resolves:
         - `$HYPRSHOT_DIR`
         - `$XDG_PICTURES_DIR`
         - `$(xdg-user-dir PICTURES)`
      '';
    };
  };

  config.home = lib.mkIf cfg.enable {
    packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    sessionVariables = lib.mkIf (cfg.saveLocation != null) { HYPRSHOT_DIR = cfg.saveLocation; };
  };
}
