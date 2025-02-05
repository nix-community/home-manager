{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      msmtp.enable = true;
      neomutt = {
        enable = true;
        extraConfig = ''
          color status cyan default
        '';
      };
      imap.port = 993;
    };
  };

  programs.neomutt.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileExists home-files/.config/neomutt/hm@example.com
    assertFileContent home-files/.config/neomutt/neomuttrc ${
      ./neomutt-expected.conf
    }
    assertFileContent home-files/.config/neomutt/hm@example.com ${
      ./hm-example.com-msmtp-expected.conf
    }
  '';
}
