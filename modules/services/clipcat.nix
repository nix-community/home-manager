{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.clipcat;

  formatter = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.services.clipcat = {
    enable = mkEnableOption "clipcat";
    package = mkPackageOption pkgs "clipcat" { };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    enableSystemdUnit = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Enable clipcat's Systemd Unit.
      '';
    };
    daemonSettings = mkOption {
      type = formatter.type;
      default = {
        daemonize = true;
      };
      example = ''
        {
          daemonize = true;
          max_history = 50;
          history_file_path = "/home/<username>/.cache/clipcat/clipcatd-history";
          pid_file = "/run/user/<user-id>/clipcatd.pid";
          primary_threshold_ms = 5000;
          log = {
            file_path = "/path/to/log/file";
            emit_journald = true;
            emit_stdout = false;
            emit_stderr = false;
            level = "INFO";
          };
        }
      '';
      description = ''
        Configuration settings for clipcatd. All available options can be found
        here: <https://github.com/xrelkd/clipcat?tab=readme-ov-file#configuration>.
      '';
    };
    ctlSettings = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        {
          server_endpoint = "/run/user/<user-id>/clipcat/grpc.sock";
          log = {
            file_path = "/path/to/log/file";
            emit_journald = true;
            emit_stdout = false;
            emit_stderr = false;
            level = "INFO";
          };
        }
      '';
      description = ''
        Configuration settings for clipcatctl. All available options can be found
        here: <https://github.com/xrelkd/clipcat?tab=readme-ov-file#configuration>.
      '';
    };
    menuSettings = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        {
          server_endpoint = "/run/user/<user-id>/clipcat/grpc.sock";
          finder = "rofi";
          rofi = {
            line_length = 100;
            menu_length = 30;
            menu_prompt = "Clipcat";
            extra_arguments = [
              "-mesg"
              "Please select a clip"
            ];
          };
          dmenu = {
            line_length = 100;
            menu_length = 30;
            menu_prompt = "Clipcat";
          };
        }
      '';
      description = ''
        Configuration settings for clipcat-menu. All available options can be found
        here: <https://github.com/xrelkd/clipcat?tab=readme-ov-file#configuration>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipcat" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      if type clipcat-menu >/dev/null 2>&1; then
          alias clipedit=' clipcat-menu --finder=builtin edit'
          alias clipdel=' clipcat-menu --finder=builtin remove'

          bindkey -s '^\' "^Q clipcat-menu --finder=builtin insert ^J"
          bindkey -s '^]' "^Q clipcat-menu --finder=builtin remove ^J"
      fi
    '';

    systemd.user.services.clipcat = mkIf cfg.enableSystemdUnit {
      Unit = {
        Description = "Clipcat Daemon";
        PartOf = "graphical-session.target";
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStartPre = "${pkgs.writeShellScript "clipcatd-exec-start-pre" ''
          PATH=/run/current-system/sw/bin:
          rm -f %t/clipcat/grpc.sock
        ''}";

        ExecStart = "${pkgs.writeShellScript "clipcatd-exec-start" ''
          PATH=/run/current-system/sw/bin:
          ${cfg.package}/bin/clipcatd --no-daemon --replace
        ''}";

        Restart = "on-failure";
        Type = "simple";
      };
    };

    xdg.configFile = {
      "clipcat/clipcatd.toml" = mkIf (cfg.daemonSettings != { }) {
        source = formatter.generate "clipcatd.toml" cfg.daemonSettings;
      };
      "clipcat/clipcatctl.toml" = mkIf (cfg.ctlSettings != { }) {
        source = formatter.generate "clipcatctl.toml" cfg.ctlSettings;
      };
      "clipcat/clipcat-menu.toml" = mkIf (cfg.menuSettings != { }) {
        source = formatter.generate "clipcat-menu.toml" cfg.menuSettings;
      };
    };
  };
}
