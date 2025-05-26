{ ... }:
{
  programs.delta = {
    enable = true;
    settings = {
      features = "decorations";
      whitespace-error-style = "22 reverse";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./example-settings-expected.conf}
  '';
}
