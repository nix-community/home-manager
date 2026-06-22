{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitMinimal;
    signing.format = null;
    settings = [
      {
        credential."https://example.com".helper = "";
      }
      {
        credential."https://example.com".helper = "oauth";
      }
      {
        credential.helper = "store";
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-settings-ordered-fragments-expected.conf}
  '';
}
