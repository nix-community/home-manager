{ ... }:

{
  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [{
        title = "My Pull Requests";
        filters = "is:open author:@me";
      }];
    };
  };

  test.stubs.gh = { };

  nmt.script = ''
    assertFileExists home-files/.config/gh-dash/config.yml
    assertFileContent home-files/.config/gh-dash/config.yml ${
      builtins.toFile "config-file.yml" ''
        prSections:
        - filters: is:open author:@me
          title: My Pull Requests
      ''
    }
  '';
}
