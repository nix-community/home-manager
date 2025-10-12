{
  programs.vivid = {
    enable = true;
    colorMode = "8-bit";
    filetypes = {
      text = {
        special = [
          "CHANGELOG.md"
          "CODE_OF_CONDUCT.md"
          "CONTRIBUTING.md"
        ];

        todo = [
          "TODO.md"
          "TODO.txt"
        ];

        licenses = [
          "LICENCE"
          "COPYRIGHT"
        ];
      };
    };

    activeTheme = "mocha";
    themes = {
      ayu = ./themes/ayu.yml;
      mocha = ./themes/mocha.yml;
      tiny = import ./themes/tiny.nix;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/vivid/filetypes.yml
    assertFileContent home-files/.config/vivid/filetypes.yml \
    ${./filetypes.yml}

    assertFileExists home-files/.config/vivid/themes/ayu.yml
    assertFileContent home-files/.config/vivid/themes/ayu.yml \
    ${./themes/ayu.yml}

    assertFileExists home-files/.config/vivid/themes/mocha.yml
    assertFileContent home-files/.config/vivid/themes/mocha.yml \
    ${./themes/mocha.yml}

    assertFileExists home-files/.config/vivid/themes/tiny.yml
    assertFileContent home-files/.config/vivid/themes/tiny.yml \
    ${./themes/tiny.yml}
  '';
}
