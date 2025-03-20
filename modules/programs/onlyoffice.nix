{ lib, pkgs, config, ... }:

let
  inherit (lib)
    types isBool boolToString concatStringsSep mapAttrsToList mkIf
    mkEnableOption mkPackageOption mkOption;

  cfg = config.programs.onlyoffice;

  attrToString = name: value:
    let newvalue = if (isBool value) then (boolToString value) else value;
    in "${name}=${newvalue}";

  getFinalConfig = set:
    (concatStringsSep "\n" (mapAttrsToList attrToString set)) + "\n";
in {
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.onlyoffice = {
    enable = mkEnableOption "onlyoffice";

    package =
      mkPackageOption pkgs "onlyoffice-desktopeditors" { nullable = true; };

    settings = mkOption {
      type = with types; attrsOf (either bool str);
      default = { };
      example = ''
        UITheme = "theme-contrast-dark";
        editorWindowMode = false;
        forcedRtl = false;
        maximized = true;
        titlebar = "custom";
      '';
      description = ''
        Configuration settings for Onlyoffice.

        All configurable options can be deduced by enabling them through the
        GUI and observing the changes in ~/.config/onlyoffice/DesktopEditors.conf.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."onlyoffice/DesktopEditors.conf".source =
      pkgs.writeText "DesktopEditors.conf" (getFinalConfig cfg.settings);
  };
}
