{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.wl-clip-persist;
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.services.wl-clip-persist = {
    enable = lib.mkEnableOption "wl-clip-persist, a Wayland clipboard persistence tool";

    package = lib.mkPackageOption pkgs "wl-clip-persist" { };

    clipboardType = lib.mkOption {
      type = lib.types.enum [
        "regular"
        "primary"
        "both"
      ];
      default = "regular";
      description = ''
        The clipboard type to persist.

        - `regular`: Persist the regular clipboard only (recommended).
        - `primary`: Persist the primary selection only.
        - `both`: Persist both regular and primary clipboards.

        Note: Operating on the primary clipboard may have unintended side effects
        for some applications.
      '';
    };

    extraOptions = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [
        "--write-timeout"
        "1000"
        "--ignore-event-on-error"
        "--all-mime-type-regex"
        "'(?i)^(?!image/).+'"
        "--selection-size-limit"
        "1048576"
      ];
      description = ''
        Extra command-line arguments to pass to wl-clip-persist.

        Available options include:
        - `--write-timeout <ms>`: Timeout for writing clipboard data (default: 3000).
        - `--ignore-event-on-error`: Only handle events without errors.
        - `--all-mime-type-regex <regex>`: Filter events by MIME type regex.
        - `--selection-size-limit <bytes>`: Limit clipboard data size.
        - `--reconnect-tries <n>`: Number of reconnection attempts.
        - `--reconnect-delay <ms>`: Delay between reconnect attempts (default: 100).
        - `--disable-timestamps`: Disable log timestamps.
      '';
    };

    systemdTargets = lib.mkOption {
      type = with lib.types; either (listOf str) str;
      default = [ config.wayland.systemd.target ];
      defaultText = lib.literalExpression "[ config.wayland.systemd.target ]";
      example = "sway-session.target";
      description = ''
        The systemd targets that will automatically start the wl-clip-persist service.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wl-clip-persist" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.wl-clip-persist = {
      Unit = {
        Description = "Wayland clipboard persistence daemon";
        PartOf = lib.toList cfg.systemdTargets;
        After = lib.toList cfg.systemdTargets;
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} --clipboard ${cfg.clipboardType} ${lib.escapeShellArgs cfg.extraOptions}";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = lib.toList cfg.systemdTargets;
      };
    };
  };
}
