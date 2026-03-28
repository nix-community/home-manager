{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.telegram;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.hm.maintainers.oneorseveralcats ];

  options.programs.telegram = {
    enable = lib.mkEnableOption "Telegram the instant messaging client";

    package = lib.mkPackageOption pkgs "telegram-desktop" { nullable = true; };

    bindings = lib.mkOption {
      type = jsonFormat.type;
      default = [ ];
      example = [
        {
          command = "previous_chat";
          keys = "alt+k";
        }
        {
          command = "next_chat";
          keys = "alt+j";
        }
        {
          command = "search";
          keys = "alt+/";
        }
      ];
      description = ''
        Telegram keybindings.

        Full list is available at
        {file}`$XDG_DATA_HOME/TelegramDesktop/tdata/shortcuts-default.json`
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "Telegram systemd integration";

      targets = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "graphical-session.target" ];
        example = [ "tray.target" ];
        description = ''
          The systemd targets that will automatically start Telegram.
        '';
      };

      extraArgs = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "-startintray" ];
        description = ''
          Arguments to pass to the Telegram systemd service.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.dataFile."TelegramDesktop/tdata/shortcuts-custom.json" = lib.mkIf (cfg.bindings != [ ]) {
      source = jsonFormat.generate "shortcuts-custom.json" cfg.bindings;
    };

    systemd.user.services.telegram = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Telegram, the instant messaging client";
        Documentation = "https://github.com/telegramdesktop/tdesktop/wiki";
        PartOf = cfg.systemd.targets;
        After = cfg.systemd.targets;
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} ${toString cfg.systemd.extraArgs}";
        Restart = "on-failure";
      };

      Install.WantedBy = cfg.systemd.targets;
    };
  };
}
