{
  programs.aerospace = {
    enable = true;
    userSettings = {
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
      };
    };
  };

  test.stubs.aerospace = { };

  nmt.script = ''
    assertFileContent home-files/.config/aerospace/aerospace.toml ${
      ./settings-expected.toml
    }
  '';
}
