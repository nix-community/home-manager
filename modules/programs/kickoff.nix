{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.kickoff;

  formatter = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.kickoff = {
    enable = mkEnableOption "kickoff";
    package = mkPackageOption pkgs "kickoff" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        padding = 100;
        font_size = 32;
        search.show_hidden_files = false;
        history.decrease_interval = 48;

        keybinding = {
          paste = [ "ctrl+v" ];
          execute = [ "KP_Enter" "Return" ];
          complete = [ "Tab" ];
        };
      '';
      description = ''
        Configuration settings for kickoff. All the available options can be found
        here: <https://github.com/j0ru/kickoff/blob/main/assets/default_config.toml>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.kickoff" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = mkIf (cfg.settings != { }) {
      "kickoff/config.toml".source = formatter.generate "kickoff-config-toml" cfg.settings;
    };
  };
}
