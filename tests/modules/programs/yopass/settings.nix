{
  programs.yopass = {
    enable = true;
    settings = {
      api = "https://api.example.com";
      url = "https://example.com";
      "one-time" = false;
      expiration = "1d";
    };
  };

  test.stubs.yopass = { };

  nmt.script = ''
    assertFileExists home-files/.config/yopass/defaults.yml
    assertFileContent home-files/.config/yopass/defaults.yml \
      ${./settings.yml}
  '';
}
