{
  programs.sketchybar = {
    enable = true;
    sketchybarrc = ''
      PLUGIN_DIR="$CONFIG_DIR/plugins"

      sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/sketchybar/sketchybarrc
    assertFileContent home-files/.config/sketchybar/sketchybarrc \
    ${./sketchybarrc}
  '';
}
