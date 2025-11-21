{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.devilspie2;
in
{
  meta.maintainers = [ lib.maintainers.dawidsowa ];

  options = {
    services.devilspie2 = {
      enable = lib.mkEnableOption ''
        Devilspie2, a window matching utility, allowing the user to
        perform scripted actions on windows as they are created'';

      package = lib.mkPackageOption pkgs "devilspie2" { };

      config = lib.mkOption {
        type = lib.types.lines;
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.devilspie2" pkgs lib.platforms.linux)
    ];

    systemd.user.services.devilspie2 = {
      Service.ExecStart = "${lib.getExe cfg.package}";
      Unit = {
        Description = "devilspie2";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile."devilspie2/config.lua".text = cfg.config;
  };
}
