{
  programs.hyprland-qt-support = {
    enable = true;

    settings = {
      roundness = 2;
      border_width = 1;
      reduce_motion = true;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/hypr/application-style.conf \
      ${./basic-configuration.conf}
  '';
}
