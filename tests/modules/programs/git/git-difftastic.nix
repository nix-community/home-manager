{
  programs.git = {
    enable = true;
    signing.signer = "path-to-gpg";
    difftastic = {
      enable = true;
      enableAsDifftool = true;
      background = "dark";
      color = "always";
      display = "inline";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-difftastic-expected.conf}
  '';
}
