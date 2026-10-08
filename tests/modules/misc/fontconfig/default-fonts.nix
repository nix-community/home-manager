let
  configFile = "home-files/.config/fontconfig/conf.d/52-hm-default-fonts.conf";
in
{
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [
        "A"
        "B"
      ];
      emoji = [ "C" ];
    };
  };

  nmt.script = ''
    assertFileExists ${configFile}
    assertFileContent ${configFile} ${builtins.toFile "fonts.conf" ''
      <?xml version="1.0" encoding="utf-8"?>
      <fontconfig>
        <alias binding="same">
          <family>emoji</family>
          <prefer>
            <family>C</family>
          </prefer>
        </alias>
        <alias binding="same">
          <family>sans-serif</family>
          <prefer>
            <family>A</family>
            <family>B</family>
          </prefer>
        </alias>
        <description>Set default fonts</description>
      </fontconfig>
    ''}
  '';
}
