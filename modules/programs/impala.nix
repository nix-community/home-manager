{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.impala;
  tomlFormat = pkgs.formats.toml { };
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    ;
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.impala = {
    enable = mkEnableOption "impala, a TUI for iwd network";
    package = mkPackageOption pkgs "impala" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        access_point = {
          start = "n";
          stop = "x";
        };
        ascii = false;
        device = {
          infos = "i";
          toggle_power = "o";
        };
        esc_quit = false;
        mode = "station";
        station = {
          known_network = {
            remove = "d";
            share = "p";
            show_all = "a";
            toggle_autoconnect = "t";
          };
          new_network = {
            connect_hidden = "";
            show_all = "a";
          };
          toggle_scanning = "s";
        };
        switch = "r";
        theme = {
          background = "dark gray";
          border = "green";
          error_color = "red";
          hidden_color = "dark gray";
          info_color = "green";
          text_color = "white";
          warning_color = "yellow";
        };
      };
      description = ''
        Settings writteng to {file}`XDG_CONFIG_HOME/impala/config.toml`.

        See <https://github.com/pythops/impala#%EF%B8%8Fcustom-keybindings-and-themes>
        for more configuration options.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.impala" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."impala/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "hm_impala-config.toml" cfg.settings;
    };
  };
}
