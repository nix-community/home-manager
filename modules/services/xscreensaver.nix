{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.xscreensaver;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.xscreensaver = {
      enable = lib.mkEnableOption "XScreenSaver";

      settings = lib.mkOption {
        type = with lib.types; attrsOf (either bool (either int str));
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

      package = lib.mkOption {
        type = with lib.types; package;
        default = pkgs.xscreensaver;
        defaultText = lib.literalExpression "pkgs.xscreensaver";
        description = "Which xscreensaver package to use.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xscreensaver" pkgs lib.platforms.linux)
    ];

    # To make the lib.xscreensaver-command tool available.
    home.packages = [ cfg.package ];

    xresources.properties = lib.mapAttrs' (n: lib.nameValuePair "xscreensaver.${n}") cfg.settings;

    systemd.user.services.xscreensaver = {
      Unit = {
        Description = "XScreenSaver";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];

        # Make sure the service is restarted if the settings change.
        X-Restart-Triggers = [ (builtins.hashString "md5" (builtins.toJSON cfg.settings)) ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/xscreensaver -no-splash";
        Environment = [ "PATH=${lib.makeBinPath [ cfg.package ]}" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
