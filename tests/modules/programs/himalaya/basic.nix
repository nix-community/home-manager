{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      imap.port = 993;
      smtp.port = 465;
      himalaya.enable = true;
    };
  };

  programs.himalaya = { enable = true; };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./basic-expected.toml
    }
  '';
}
