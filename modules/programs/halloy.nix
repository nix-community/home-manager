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

  cfg = config.programs.halloy;

  formatter = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.halloy = {
    enable = mkEnableOption "halloy";
    package = mkPackageOption pkgs "halloy" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = {
        "buffer.channel.topic".enabled = true;
        "servers.liberachat" = {
          nickname = "halloy-user";
          server = "irc.libera.chat";
          channels = [ "#halloy" ];
        };
      };
      description = ''
        Configuration settings for halloy. All available options can be
        found here: <https://halloy.chat/configuration/index.html>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."halloy/config.toml" = mkIf (cfg.settings != { }) {
      source = formatter.generate "halloy-config" cfg.settings;
    };
  };
}
