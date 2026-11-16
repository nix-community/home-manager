{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      imap.port = 993;
      imap.authentication = "login";
      smtp.port = 465;
      smtp.authentication = "login";
      himalaya.enable = true;
    };
  };

  programs.himalaya = {
    enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${./basic-expected.toml}
  '';
}
