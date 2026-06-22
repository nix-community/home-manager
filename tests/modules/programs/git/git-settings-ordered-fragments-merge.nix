{ lib, pkgs, ... }:
{
  programs.git = lib.mkMerge [
    {
      enable = true;
      package = pkgs.gitMinimal;
      signing.format = null;
      settings = [
        {
          credential."https://example.com".helper = "";
        }
      ];
    }
    {
      settings = [
        {
          credential."https://example.com".helper = "oauth";
        }
      ];
    }
    {
      settings = [
        {
          credential.helper = "store";
        }
      ];
    }
  ];

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-settings-ordered-fragments-merge-expected.conf}
  '';
}
