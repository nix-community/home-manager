let
  configFile = "home-files/.config/fontconfig/conf.d/10-hm-rendering.conf";
in
{
  fonts.fontconfig = {
    enable = true;
    antialiasing = false;
    hinting = "none";
    subpixelRendering = "vertical-bgr";
  };

  nmt.script = ''
    assertFileExists ${configFile}
    assertFileContent ${configFile} ${builtins.toFile "rendering.conf" ''
      <?xml version="1.0" encoding="utf-8"?>
      <fontconfig>
        <description>Set the rendering mode</description>
        <match target="font">
          <edit mode="assign" name="antialias">
            <bool>false</bool>
          </edit>
          <edit mode="assign" name="hinting">
            <bool>true</bool>
          </edit>
          <edit mode="assign" name="hintstyle">
            <const>hintnone</const>
          </edit>
          <edit mode="assign" name="rgba">
            <const>vbgr</const>
          </edit>
        </match>
      </fontconfig>
    ''}
  '';
}
