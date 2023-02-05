{ ... }:

{
  programs.papis = {
    enable = true;
    settings = {
      picktool = "fzf";
      file-browser = "ranger";
      add-edit = true;
    };
    libraries = {
      papers = {
        isDefault = true;
        settings = {
          dir = "~/papers";
          opentool = "okular";
        };
      };
      books.settings = {
        dir = "~/books";
        opentool = "firefox";
      };
    };
  };

  test.stubs.papis = { };

  nmt.script = ''
    assertFileContent home-files/.config/papis/config \
    ${builtins.toFile "papis-expected-settings.ini" ''
      [books]
      dir=~/books
      opentool=firefox

      [papers]
      dir=~/papers
      opentool=okular

      [settings]
      add-edit=true
      default-library=papers
      file-browser=ranger
      picktool=fzf
    ''}
  '';
}
