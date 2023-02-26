{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mpd-discord-rpc;
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "config.toml" cfg.settings;
in {
  meta.maintainers = [ maintainers.kranzes ];

  options.services.mpd-discord-rpc = {
    enable = mkEnableOption "the mpd-discord-rpc service";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          hosts = [ "localhost:6600" ];
          format = {
            details = "$title";
            state = "On $album by $artist";
          };
        }
      '';
      description = ''
        Configuration included in <literal>config.toml</literal>.
        For available options see <link xlink:href="https://github.com/JakeStanger/mpd-discord-rpc#configuration"/>
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.mpd-discord-rpc;
      defaultText = literalExpression "pkgs.mpd-discord-rpc";
      description = "mpd-discord-rpc package to use.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.mpd-discord-rpc" pkgs
        platforms.linux)
    ];

    xdg.configFile."discord-rpc/config.toml".source = configFile;

    systemd.user.services.mpd-discord-rpc = {
      Unit = {
        Description = "Discord Rich Presence for MPD";
        Documentation = "https://github.com/JakeStanger/mpd-discord-rpc";
        After = [ "graphical-session-pre.target" ];
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
