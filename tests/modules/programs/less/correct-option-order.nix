{
  programs.less = {
    enable = true;
    options = {
      color = [
        "HkK" # header: gray
        "Mkb" # marks: blue
      ];
      prompt = "s%f";
      quiet = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${builtins.toFile "lesskey.expected" ''
      #env
      LESS = --quiet --color HkK --color Mkb --prompt s%f
    ''}
  '';
}
