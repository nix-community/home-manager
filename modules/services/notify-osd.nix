{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.notify-osd;

in
{
  meta.maintainers = [ lib.maintainers.imalison ];

  options = {
    services.notify-osd = {
      enable = lib.mkEnableOption "notify-osd";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.notify-osd;
        defaultText = lib.literalExpression "pkgs.notify-osd";
        description = ''
          Package containing the {command}`notify-osd` program.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.notify-osd" pkgs lib.platforms.linux)
    ];

    systemd.user.services.notify-osd = {
      Unit = {
        Description = "notify-osd";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${cfg.package}/bin/notify-osd";
        Restart = "on-abort";
      };
    };
  };
}
