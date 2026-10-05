{
  programs.go-musicfox = {
    enable = true;

    settings = {
      startup = {
        enable = true;
        progressOutBounce = true;
        loadingSeconds = 2;
      };

      main = {
        altScreen = true;
        enableMouseEvent = true;
        debug = false;
        visualizer = {
          enable = false;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/go-musicfox/config.toml"
    assertFileContent "home-files/.config/go-musicfox/config.toml" ${./expected.toml}
  '';
}
