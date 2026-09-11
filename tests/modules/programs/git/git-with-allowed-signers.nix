{
  programs.git = {
    enable = true;
    signing = {
      allowedSigners = ''
        user@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKey
      '';
      format = "ssh";
      signer = "path-to-ssh";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/allowed_signers
    assertFileContent home-files/.config/git/allowed_signers ${./git-allowed-signers-expected}
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-with-allowed-signers-expected.conf}
  '';
}
