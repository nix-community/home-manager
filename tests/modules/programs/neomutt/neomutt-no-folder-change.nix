{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      msmtp.enable = true;
      neomutt.enable = true;
      imap.port = 993;
    };
  };

  programs.neomutt.enable = true;
  programs.neomutt.changeFolderWhenSourcingAccount = false;

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/hm@example.com
    assertFileContent home-files/.config/neomutt/hm@example.com ${
      ./hm-example.com-no-folder-change-expected.conf
    }
  '';
}
