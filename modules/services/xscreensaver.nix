{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xscreensaver;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.xscreensaver = {
      enable = mkEnableOption "XScreenSaver";

      settings = mkOption {
        type = with types; attrsOf (either bool (either int str));
        default = { };
        example = {
          mode = "blank";
          lock = false;
          fadeTicks = 20;
        };
        description = ''
          The settings to use for XScreenSaver.
        '';
      };

      package = mkOption {
        type = with types; package;
        default = pkgs.xscreensaver;
        defaultText = lib.literalExpression "pkgs.xscreensaver";
        description = "Which xscreensaver package to use.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xscreensaver" pkgs
        lib.platforms.linux)
    ];

    # To make the xscreensaver-command tool available.
    home.packages = [ cfg.package ];

    xresources.properties =
      mapAttrs' (n: nameValuePair "xscreensaver.${n}") cfg.settings;

    systemd.user.services.xscreensaver = {
      Unit = {
        Description = "XScreenSaver";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];

        # Make sure the service is restarted if the settings change.
        X-Restart-Triggers =
          [ (builtins.hashString "md5" (builtins.toJSON cfg.settings)) ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/xscreensaver -no-splash";
        Environment = [ "PATH=${makeBinPath [ cfg.package ]}" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
