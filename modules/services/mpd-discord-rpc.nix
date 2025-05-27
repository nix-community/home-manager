{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mpd-discord-rpc;
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "config.toml" cfg.settings;
in
{
  meta.maintainers = [ lib.maintainers.kranzes ];

  options.services.mpd-discord-rpc = {
    enable = lib.mkEnableOption "the mpd-discord-rpc service";

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          hosts = [ "localhost:6600" ];
          format = {
            details = "$title";
            state = "On $album by $artist";
          };
        }
      '';
      description = ''
        Configuration included in `config.toml`.
        For available options see <https://github.com/JakeStanger/mpd-discord-rpc#configuration>
      '';
    };

    package = lib.mkPackageOption pkgs "mpd-discord-rpc" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpd-discord-rpc" pkgs lib.platforms.linux)
    ];

    xdg.configFile."discord-rpc/config.toml".source = configFile;

    systemd.user.services.mpd-discord-rpc = {
      Unit = {
        Description = "Discord Rich Presence for MPD";
        Documentation = "https://github.com/JakeStanger/mpd-discord-rpc";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/mpd-discord-rpc";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
