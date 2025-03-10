{
  programs.micro = {
    enable = true;

    settings = {
      autosu = false;
      cursorline = false;
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/micro/settings.json \
    ${builtins.toFile "micro-expected-settings.json" ''
      {
        "autosu": false,
        "cursorline": false
      }
    ''}
  '';
}
