{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.autorandr;
in
{
  meta.maintainers = [
    lib.maintainers.GaetanLepage
    lib.hm.maintainers.lowlevl
  ];

  options = {
    services.autorandr = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable the Autorandr systemd service.
          This module is complementary to {option}`programs.autorandr`
          which handles the configuration (profiles).

          This user service will only trigger during `graphical-session.target`
          (i.e. when the user logs into the graphical session). It won't
          trigger when you plug or unplug monitors. If you want the user
          service to trigger on plug events, add this udev rule to your system
          configuration:
          ```nix
          services.udev.extraRules = '''
            ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", \
              TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="autorandr.service"
          ''';
          ```
        '';
      };

      package = lib.mkPackageOption pkgs "autorandr" { };

      ignoreLid = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Treat outputs as connected even if their lids are closed.";
      };

      matchEdid = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Match displays based on edid instead of name.";
      };

      extraOptions = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        example = [
          "--force"
        ];
        description = "Extra options to pass to Autorandr.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.autorandr" pkgs lib.platforms.linux)
    ];

    systemd.user.services.autorandr = {
      Unit = {
        Description = "Auto-detect the connected display hardware and load the appropriate X11 setup using xrandr";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart =
          let
            args = lib.escapeShellArgs (
              lib.optional cfg.ignoreLid "--ignore-lid"
              ++ lib.optional cfg.matchEdid "--match-edid"
              ++ cfg.extraOptions
            );
          in
          "${lib.getExe cfg.package} --change ${args}";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
