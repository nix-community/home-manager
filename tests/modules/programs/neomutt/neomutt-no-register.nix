{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      neomutt = {
        enable = true;
        registerAccount = false;
      };
    };
  };

  programs.neomutt.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileContent home-files/.config/neomutt/neomuttrc ${./neomutt-no-register-expected.conf}
  '';
}
