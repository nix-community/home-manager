{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.go-musicfox;
  settingsFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = [ lib.maintainers.luke ];

  options.programs.go-musicfox = {
    enable = lib.mkEnableOption "Terminal netease cloud music client written in Go";

    package = lib.mkPackageOption pkgs "go-musicfox" { nullable = true; };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      example = {
        startup = {
          enable = true;
          progressOutBounce = true;
          loadingSeconds = 2;
          welcome = "musicfox";
          checkUpdate = true;
        };
      };
      description = ''
        go-muficfox configuration.
        For available settings see <https://github.com/go-musicfox/go-musicfox/blob/master/utils/filex/embed/config.toml>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."go-musicfox/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "go-musicfox-config.toml" cfg.settings;
    };
  };
}
