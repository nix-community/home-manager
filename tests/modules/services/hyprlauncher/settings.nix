{
  services.hyprlauncher = {
    enable = true;
    settings = {
      general.grab_focus = true;
      cache.enabled = true;
      ui.window_size = "400 260";
      finders = {
        math_prefix = "=";
        desktop_icons = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/hypr/hyprlauncher.conf
    assertFileContent home-files/.config/hypr/hyprlauncher.conf \
      ${./hyprlauncher.conf}
  '';
}
