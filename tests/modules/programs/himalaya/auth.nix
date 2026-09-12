{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    # OAuth mechanisms carry a token, not a password
    "hm@example.com" = {
      imap.authentication = "xoauth2";
      smtp.authentication = "login";
      himalaya.enable = true;
    };

    # JMAP is reached over HTTP, so it authenticates with an HTTP
    # scheme rather than SASL
    jmap-account = {
      address = "jmap@example.com";
      userName = "jmap";
      realName = "JMAP Test";
      passwordCommand = "password-command";
      imap = null;
      smtp = null;
      jmap = {
        host = "jmap.example.com";
        sessionUrl = "https://jmap.example.com/.well-known/jmap";
      };
      himalaya.enable = true;
    };

    # no credential to send: the mechanism transmits none
    anon-account = {
      address = "anon@example.com";
      userName = "anon";
      realName = "Anon Test";
      imap = {
        host = "imap.example.com";
        authentication = "anonymous";
      };
      smtp = null;
      himalaya.enable = true;
    };
  };

  programs.himalaya.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${./auth-expected.toml}
  '';
}
