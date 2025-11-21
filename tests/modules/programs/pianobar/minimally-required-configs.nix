{
  programs.pianobar = {
    enable = true;
    settings = {
      password_command = "cat /run/secrets/pianobar/groovy-tunes";
      user = "groovy-tunes@example.com";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/pianobar/config
    assertFileContent home-files/.config/pianobar/config \
    ${./minimally-required-configs.conf}
  '';
}
