{
  programs.pianobar = {
    enable = true;
    user = "groovy-tunes@example.com";
    password_command = "cat /run/secrets/pianobar/groovy-tunes";
  };

  nmt.script = ''
    assertFileExists home-files/.config/pianobar/config
    assertFileContent home-files/.config/pianobar/config \
    ${./minimally-required-configs.conf}
  '';
}
