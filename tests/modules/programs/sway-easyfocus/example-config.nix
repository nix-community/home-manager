{
  programs.sway-easyfocus = {
    enable = true;
    settings = {
      chars = "fjghdkslaemuvitywoqpcbnxz";
      window_background_color = "d1f21";
      window_background_opacity = 0.2;
      focused_background_color = "285577";
      focused_background_opacity = 1.0;
      focused_text_color = "ffffff";
      font_family = "monospace";
      font_weight = "bold";
      font_size = "medium";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway-easyfocus/config.yaml
    assertFileContent home-files/.config/sway-easyfocus/config.yaml \
    ${./config.yaml}
  '';
}
