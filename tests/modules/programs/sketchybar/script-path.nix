{
  programs.sketchybar = {
    enable = true;
    sketchybarrc = ./sketchybarrc;
  };

  nmt.script = ''
    assertFileExists home-files/.config/sketchybar/sketchybarrc
    assertFileContent home-files/.config/sketchybar/sketchybarrc \
    ${./sketchybarrc}
  '';
}
