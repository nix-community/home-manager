{
  programs.inkscape = {
    enable = true;

    templates = {
      "banner.svg" = ''
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="800" height="200"/>
      '';
    };

    colorPalettes = {
      "brand.gpl" = ''
        GIMP Palette
        Name: Brand Colors
        #FF0000 Red
      '';
    };

    fontCollections = {
      "design.txt" = ''
        Inter
        Roboto Mono
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/inkscape/templates/banner.svg
    assertFileContains \
      home-files/.config/inkscape/templates/banner.svg \
      'width="800"'

    assertFileExists home-files/.config/inkscape/palettes/brand.gpl
    assertFileContains \
      home-files/.config/inkscape/palettes/brand.gpl \
      'Brand Colors'

    assertFileExists home-files/.config/inkscape/fontscollections/design.txt
    assertFileContains \
      home-files/.config/inkscape/fontscollections/design.txt \
      'Roboto Mono'
  '';
}
