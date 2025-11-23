{ lib, ... }:

{
  programs.less = {
    enable = true;
    options = lib.mkMerge [
      {
        quiet = true;
        use-color = true;
      }
      (lib.mkAfter {
        color = [
          "HkK" # header: gray
          "Mkb" # marks: blue
        ];
      })
      (lib.mkOrder 2000 {
        prompt = "s%f";
      })
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/lesskey
    assertFileContent home-files/.config/lesskey ${builtins.toFile "lesskey.expected" ''
      #env
      LESS = --quiet --use-color --color HkK --color Mkb --prompt s%f
    ''}
  '';
}
