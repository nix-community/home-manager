{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.elephant;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ ratakor ];

  options.services.elephant = {
    enable = lib.mkEnableOption "elephant";

    package = lib.mkPackageOption pkgs "elephant" {
      example = ''
        pkgs.elephant.override {
          enabledProviders = [
            "desktopapplications"
            "runner"
          ];
        }
      '';
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        providers.default = [
          "desktopapplications"
          "runner"
        ];
      };
      description = ''
        Configuration settings for Elephant.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.elephant" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."elephant/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "elephant-config" cfg.settings;
    };

    systemd.user.services.elephant = {
      Unit = {
        Description = "Elephant - Data provider for application launchers";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };
  };
}
