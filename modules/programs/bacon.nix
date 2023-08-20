{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bacon;

  settingsFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.shimunn ];

  options.programs.bacon = {
    enable = mkEnableOption "bacon, a background rust code checker";

    settings = mkOption {
      type = settingsFormat.type;
      example = {
        jobs.default = {
          command = [ "cargo" "build" "--all-features" "--color" "always" ];
          need_stdout = true;
        };
      };
      description = ''
        Bacon configuration.
        For available settings see <https://dystroy.org/bacon/#global-preferences>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bacon ];

    xdg.configFile."bacon/prefs.toml".source =
      settingsFormat.generate "prefs.toml" cfg.settings;
  };
}
