{
  programs.amfora = {
    enable = true;
    settings = {
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

    bookmarks = ''
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
  };

  nmt.script = ''
    assertFileExists home-files/.config/amfora/config.toml
    assertFileContent home-files/.config/amfora/config.toml \
      ${./config.toml}

    assertFileExists home-files/.local/share/amfora/bookmarks.xml
    assertFileContent home-files/.local/share/amfora/bookmarks.xml \
      ${./bookmarks.xml}
  '';
}
