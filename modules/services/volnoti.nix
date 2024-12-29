{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.volnoti;

in {
  meta.maintainers = with maintainers; [ imalison tomodachi94 ];

  options = {
    services.volnoti = {
      enable = mkEnableOption "Volnoti volume HUD daemon";

      package = mkOption {
        type = types.package;
        default = pkgs.volnoti;
        defaultText = literalExpression "pkgs.volnoti";
        description = ''
          Package containing the {command}`volnoti` program.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.volnoti" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.volnoti = {
      Unit = { Description = "volnoti"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${lib.getExe cfg.package} -v -n"; };
    };
  };
}
