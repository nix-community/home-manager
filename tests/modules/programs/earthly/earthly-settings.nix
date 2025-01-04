_:

{
  programs.earthly = {
    enable = true;

    settings = {
      global.disable_analytics = true;

      git."github.com" = {
        auth = "ssh";
        user = "username";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.earthly/config.yml
    assertFileContent home-files/.earthly/config.yml ${./earthly-settings.yml}
  '';
}
