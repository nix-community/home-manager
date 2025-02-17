{
  programs.feh.enable = true;

  programs.feh.themes = {
    feh = [ "--image-bg" "black" ];
    webcam = [ "--multiwindow" "--reload" "20" ];
    present = [ "--full-screen" "--sort" "name" "--hide-pointer" ];
    booth = [ "--full-screen" "--hide-pointer" "--slideshow-delay" "20" ];
    imagemap = [
      "-rVq"
      "--thumb-width"
      "40"
      "--thumb-height"
      "30"
      "--index-info"
      "%n\\n%wx%h"
    ];
    example = [ "--info" "foo bar" ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/feh/themes \
      ${./feh-themes-expected}
  '';
}
