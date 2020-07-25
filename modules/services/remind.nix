{ config, lib, pkgs, ... }:

let cfg = config.services.remind;
in with lib; {
  meta.maintainers = with maintainers; [ markus1189 ];

  options.services.remind = {
    enable = mkEnableOption "remind daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.remind;
      defaultText = literalExample "pkgs.remind";
      description = "Which remind package to install.";
    };

    remindFile = mkOption {
      type = types.path;
      description =
        "Path to your main main remind file or a directory of files.";
    };

    remindCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The command that remind runs when triggered.";
      example = literalExample ''
        notify-send remind '%s'
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = { packages = [ cfg.package ]; };

    systemd.user = {
      services.remind = let
        cmd = optionalString (cfg.remindCommand != null)
          "-k${escapeShellArg cfg.remindCommand}";
        # Use a separate script due to systemd specifiers conflicting
        # with remind's substitution filter...
        script = pkgs.writeShellScript "remind-command-systemd" ''
          exec ${cfg.package}/bin/remind -z ${cmd} ${cfg.remindFile}
        '';
      in {
        Unit = { Description = "remind daemon"; };

        Service = {
          ExecStart = "${script}";
          RestartSec = 3;
          Restart = "always";
        };
      };
    };
  };
}
