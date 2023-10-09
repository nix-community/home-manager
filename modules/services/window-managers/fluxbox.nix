{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.fluxbox;

in {
  meta.maintainers = [ maintainers.AndersonTorres ];

  options = {
    xsession.windowManager.fluxbox = {
      enable = mkEnableOption "Fluxbox window manager";

      package = mkPackageOption pkgs "fluxbox" { };

      init = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Init configuration for Fluxbox, written to
          {file}`~/.fluxbox/init`. Look at the
          {manpage}`fluxbox(1)` manpage for details.
        '';
      };

      apps = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Apps configuration for Fluxbox, written to
          {file}`~/.fluxbox/apps`. Look at the
          {manpage}`fluxbox(1)` manpage for details.
        '';
      };

      keys = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Keyboard shortcuts configuration for Fluxbox, written to
          {file}`~/.fluxbox/keys`. Look at the
          {manpage}`fluxbox-keys(1)` manpage for details.
        '';
      };

      menu = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Menu configuration for Fluxbox, written to
          {file}`~/.fluxbox/menu`. Look at the
          {manpage}`fluxbox-menu(1)` manpage for details.
        '';
      };

      slitlist = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Slitlist configuration for Fluxbox, written to
          {file}`~/.fluxbox/slitlist`. Look at the
          {manpage}`fluxbox(1)` manpage for details.
        '';
      };

      windowmenu = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Window menu configuration for Fluxbox, written to
          {file}`~/.fluxbox/windowmenu`. Look at the
          {manpage}`fluxbox-menu(1)`
          manpage for details.
        '';
      };

      extraCommandLineArgs = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "-log" "/tmp/fluxbox.log" ];
        description = ''
          Extra command line arguments to pass to {command}`fluxbox`.
          Look at the
          {manpage}`fluxbox(1)` manpage for details.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "xsession.windowManager.fluxbox" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.file = {
      ".fluxbox/init" = mkIf (cfg.init != "") { text = cfg.init; };
      ".fluxbox/apps" = mkIf (cfg.apps != "") { text = cfg.apps; };
      ".fluxbox/keys" = mkIf (cfg.keys != "") { text = cfg.keys; };
      ".fluxbox/menu" = mkIf (cfg.menu != "") { text = cfg.menu; };
      ".fluxbox/slitlist" = mkIf (cfg.slitlist != "") { text = cfg.slitlist; };
      ".fluxbox/windowmenu" =
        mkIf (cfg.windowmenu != "") { text = cfg.windowmenu; };
    };

    xsession.windowManager.command = escapeShellArgs
      ([ "${cfg.package}/bin/fluxbox" ] ++ remove "" cfg.extraCommandLineArgs);
  };
}
