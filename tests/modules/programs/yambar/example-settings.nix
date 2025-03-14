{
  programs.yambar = {
    enable = true;
    settings = {
      bar = {
        location = "top";
        height = 26;
        background = "00000066";
        right = [{ clock.content = [{ string.text = "{time}"; }]; }];
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/yambar/config.yml \
      ${
        builtins.toFile "yambar-expected.yml" ''
          bar:
            background: '00000066'
            height: 26
            location: top
            right:
            - clock:
                content:
                - string:
                    text: '{time}'
        ''
      }
  '';
}
