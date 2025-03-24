{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      gpg = {
        encryptByDefault = true;
        signByDefault = true;
      };
      neomutt.enable = true;
      imap.port = 993;
    };
  };

  programs.neomutt.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileExists home-files/.config/neomutt/hm@example.com
    assertFileContent $(normalizeStorePaths home-files/.config/neomutt/neomuttrc) ${
      ./neomutt-expected.conf
    }
    assertFileContent home-files/.config/neomutt/hm@example.com ${
      ./hm-example.com-gpg-expected.conf
    }
  '';
}
