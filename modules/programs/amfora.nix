{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.amfora;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.amfora = {
    enable = mkEnableOption "amfora";
    package = mkPackageOption pkgs "amfora" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        a-general = {
          home = "gemini://geminiprotocol.net";
          auto_redirect = false;
          http = "default";
          search = "gemini://geminispace.info/search";
          color = true;
          ansi = true;
          highlight_code = true;
          highlight_style = "monokai";
          bullets = true;
        };
      };
      description = ''
        Configuration settings for amfora. All available options can be found here:
        <https://github.com/makew0rld/amfora/blob/master/default-config.toml>.
      '';
    };
    bookmarks = mkOption {
      type = with types; either str path;
      default = "";
      example = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE xbel
          PUBLIC "+//IDN python.org//DTD XML Bookmark Exchange Language 1.1//EN//XML"
                 "http://www.python.org/topics/xml/dtds/xbel-1.1.dtd">
        <xbel version="1.1">
            <bookmark href="gemini://example.com/">
                <title>Example Bookmark</title>
            </bookmark>
        </xbel>
      '';
      description = ''
        Bookmarks file for amfora. It's highly recommended that you edit
        this file through the program itself, and then look at
        $XDG_DATA_HOME/amfora/bookmarks.xml
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."amfora/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "amfora-config.toml" cfg.settings;
    };
    xdg.dataFile."amfora/bookmarks.xml" = mkIf (cfg.bookmarks != "") {
      source =
        if lib.isPath cfg.bookmarks then
          cfg.bookmarks
        else
          pkgs.writeText "amfora-bookmarks.xml" cfg.bookmarks;
    };
  };
}
