{ config, lib, pkgs, ... }:

with lib;
let cfg = config.services.devilspie2;
in {
  meta.maintainers = [ maintainers.dawidsowa ];

  options = {
    services.devilspie2 = {
      enable = mkEnableOption ''
        Devilspie2, a window matching utility, allowing the user to
        perform scripted actions on windows as they are created'';

      config = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Content of file placed in the devilspie2 config directory.
        '';
        example = ''
          if (get_window_class() == "Gnome-terminal") then
              make_always_on_top();
          end
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.devilspie2" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.devilspie2 = {
      Service.ExecStart = "${pkgs.devilspie2}/bin/devilspie2";
      Unit = {
        Description = "devilspie2";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile."devilspie2/config.lua".text = cfg.config;
  };
}
