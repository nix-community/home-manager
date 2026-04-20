{ lib, pkgs, ... }:
{
  imports = [
    (_: {
      programs.git.settings = lib.mkAfter [
        {
          credential."https://example.com".helper = "after";
        }
      ];
    })
    (_: {
      programs.git.settings = [
        {
          credential."https://example.com".helper = "middle";
        }
      ];
    })
    (_: {
      programs.git.settings = lib.mkBefore [
        {
          credential."https://example.com".helper = "before";
        }
      ];
    })
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitMinimal;
    signing.format = null;
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-settings-ordered-fragments-priority-expected.conf}
  '';
}
