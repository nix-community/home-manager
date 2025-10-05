{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  formatter = pkgs.formats.toml { };

  cfg = config.programs.asciinema;
in
{
  meta.maintainers = [
    lib.maintainers.S0AndS0
  ];

  options.programs.asciinema = {
    enable = mkEnableOption "Enable installing asciinema and writing configuration file";

    package = mkPackageOption pkgs "asciinema" {
      nullable = true;
    };

    settings = mkOption {
      inherit (formatter) type;

      default = { };

      example = {
        server.url = "https://asciinema.example.com";

        session = {
          command = "/run/current-system/sw/bin/bash -l";
          capture_input = true;
          capture_env = "SHELL,TERM,USER";
          idle_time_limit = 2;
          pause_key = "^p";
          add_marker_key = "^x";
          prefix_key = "^a";
        };

        playback = {
          speed = 2;
          pause_key = "^p";
          step_key = "s";
          next_marker_key = "m";
        };

        notifications = {
          enable = false;
          command = ''tmux display-message "$TEXT"'';
        };
      };

      description = ''
        Declare-able configurations for asciinema written to
        {file}`$XDG_CONFIG_HOME/asciinema/config.toml`.


        Check official docs for available configurations;
        https://docs.asciinema.org/manual/cli/configuration/v3/#config-file
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."asciinema/config.toml" = mkIf (cfg.settings != { }) {
      source = formatter.generate "asciinema_config.toml" cfg.settings;
    };

    home.packages = mkIf (cfg.package != null) [
      cfg.package
    ];
  };
}
