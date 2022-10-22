{ config, lib, pkgs, ... }:

let
  inherit (lib)
    hm types mkEnableOption mdDoc mkIf mkOption mkPackageOption platforms;
in {
  xsession.windowManager.hypr = {
    enable = mkEnableOption "Hypr window manager";

    package = mkPackageOption pkgs "hypr" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/hypr/hypr.conf</filename>. See
        <link xlink:href="https://github.com/hyprwm/Hypr/wiki/Configuring-Hypr" />
        for explanation about possible values.
      '';
    };
  };
}
