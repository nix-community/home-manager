{
  home.enableNixpkgsReleaseCheck = false;
  programs.wallust = {
    enable = true;
    backend = "full";
    settings = {
      backend = "fastresize";
      color_space = "lchmixed";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/wallust/wallust.toml
    assertFileContent home-files/.config/wallust/wallust.toml ${./expected.toml}
  '';
}
