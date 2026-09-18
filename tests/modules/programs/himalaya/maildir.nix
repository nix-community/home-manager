{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    # STARTTLS on SMTP, implicit TLS on IMAP, no explicit port
    hm-account = {
      imap.authentication = "plain";
      smtp.authentication = "plain";
      himalaya.enable = true;
    };

    # no IMAP configuration: falls back to the account's maildir
    "maildir@example.com" = {
      address = "maildir@example.com";
      userName = "maildir";
      realName = "Maildir Test";
      himalaya.enable = true;
    };
  };

  programs.himalaya = {
    enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${./maildir-expected.toml}
  '';
}
