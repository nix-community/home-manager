{ config, lib, pkgs, ... }:
let cfg = config.services.cliphist;
in {
  meta.maintainers = [ lib.hm.maintainers.janik ];

  options.services.cliphist = {
    enable =
      lib.mkEnableOption "cliphist, a clipboard history “manager” for wayland";

    package = lib.mkPackageOption pkgs "cliphist" { };

    allowImages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Store images in clipboard history.
      '';
    };

    extraOptions = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "-max-dedupe-search" "10" "-max-items" "500" ];
      description = ''
        Flags to append to the cliphist command.
      '';
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the cliphist service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = let extraOptionsStr = lib.escapeShellArgs cfg.extraOptions;
  in lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.cliphist" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste --watch ${cfg.package}/bin/cliphist ${extraOptionsStr} store";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };

    systemd.user.services.cliphist-images = lib.mkIf cfg.allowImages {
      Unit = {
        Description = "Clipboard management daemon - images";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${cfg.package}/bin/cliphist ${extraOptionsStr} store";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
