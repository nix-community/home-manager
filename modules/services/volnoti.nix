{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.volnoti;

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.volnoti = { enable = mkEnableOption "Volnoti volume HUD daemon"; };

    package = mkOption {
      type = types.package;
      default = pkgs.volnoti;
      defaultText = literalExample "pkgs.volnoti";
      description = ''
        Package containing the <command>volnoti</command> program.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    systemd.user.services.volnoti = {
      Unit = { Description = "volnoti"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${pkgs.volnoti}/bin/volnoti -v -n"; };
    };
  };
}
