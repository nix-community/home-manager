{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com".maildir = null;
    hm-account.neomutt.enable = true;
  };

  programs.neomutt.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileContent $(normalizeStorePaths home-files/.config/neomutt/neomuttrc) ${
      ./neomutt-not-primary-expected.conf
    }
  '';
}
