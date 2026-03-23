{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nom;
in
{
  meta.maintainers = [ lib.hm.maintainers.oneorseveralcats ];

  options.programs.nom = {
    enable = lib.mkEnableOption "nom a terminal, rss feed reader.";

    package = lib.mkPackageOption pkgs "nom" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        autoread = true;
        showread = false;
        ordering = "desc";
        openers = [
          {
            regex = "youtube";
            cmd = "mpv %s";
          }
        ];
        theme = {
          glamour = "dark";
        };
        feeds = [
          {
            name = "Jeff Geerling";
            url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCR-DXc1voovS8nhAvccRZhg";
          }
        ];
      };
      description = ''
        Settings for nom including themes, rss feeds, and openers for specific url regexes.

        Options are listed on the github: <https://github.com/guyfedwards/nom>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [
      cfg.package
    ];

    xdg.configFile."nom/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = pkgs.writeText "config.yml" (lib.generators.toYAML { } cfg.settings);
    };
  };
}
