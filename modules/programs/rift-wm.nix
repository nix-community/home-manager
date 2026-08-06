{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  cfg = config.programs.rift-wm;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.eveeifyeve ];

  options.programs.rift-wm = {
    enable = mkEnableOption "rift-wm";
    package = mkPackageOption pkgs "rift-wm" { };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Settings written to {file}`config.toml`. See the rift
        documentation for details.
      '';
    };

    launchd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Configure the launchd agent to manage the Rift-wm process.

          The first time this is enabled, macOS will prompt you to allow this background
          item in System Settings.

          You can verify the service is running correctly from your terminal.
          Run: `launchctl list | grep rift-wm`

          - A running process will show a Process ID (PID) and a status of 0, for example:
            `12345	0	org.nix-community.home.rift-wm`

          - If the service has crashed or failed to start, the PID will be a dash and the
            status will be a non-zero number, for example:
            `-	1	org.nix-community.home.rift-wm`

          In case of failure, check the logs with `cat /tmp/rift-wm.err.log`.

          For more detailed service status, run `launchctl print gui/$(id -u)/org.nix-community.home.rift-wm`.
        '';
      };
      keepAlive = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the launchd service should be kept alive.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "programs.rift-wm" pkgs lib.platforms.darwin)
      ];

      home.packages = [ cfg.package ];
      xdg.configFile."rift/config.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "rift-config.toml" cfg.settings;
      };

      launchd.agents.rift-wm = {
        inherit (cfg.launchd) enable;
        config = {
          Program = "${cfg.package}/bin/rift";
          KeepAlive = cfg.launchd.keepAlive;
          RunAtLoad = true;
          StandardOutPath = "/tmp/rift-wm.log";
          StandardErrorPath = "/tmp/rift-wm.err.log";
        };
      };
    };
  };
}
