{ lib, realPkgs, ... }:
{
  imports = [
    ../../accounts/email-test-accounts.nix
    {
      accounts.email.accounts."hm@example.com".getmail.settings = {
        retriever.imap_search = "UNSEEN";
        options.verbose = lib.mkDefault 0;
        "filter-1".type = "Filter_external";
      };
    }
    {
      accounts.email.accounts."hm@example.com".getmail.settings = {
        options.verbose = 2;
        "filter-1".path = "/bin/true";
      };
    }
  ];

  accounts.email.accounts = {
    "hm@example.com" = {
      passwordCommand = lib.mkForce [
        "password-command"
        ''argument"with-quotes''
      ];
      getmail = {
        enable = true;
        mailboxes = [ ''INBOX."quoted"'' ];
        destinationCommand = "/bin/maildrop";
        delete = true;
        readAll = lib.mkDefault false;
        settings = {
          options.delete = lib.mkForce false;
          destination.arguments = "('--message-from-stdin',)";
        };
      };
    };
    hm-account = {
      imap = lib.mkForce null;
      getmail = {
        enable = true;
        delete = lib.mkDefault true;
        settings = {
          retriever = {
            type = "SimpleIMAPSSLRetriever";
            server = "imap.native.example.org";
            port = 993;
            username = "native-user";
            mailboxes = "('INBOX', 'Archive')";
            password_command = "('helper', '--account', 'secondary')";
          };
          destination = {
            type = "MDA_external";
            path = "/bin/true";
            arguments = "('--mail',)";
          };
        };
      };
    };
  };

  services.getmail.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.config/systemd/user/getmail.service ' --rcfile getmailhm-account'
    assertFileRegex home-files/.config/systemd/user/getmail.service ' --rcfile getmailrc'
    assertPathNotExists home-files/.getmail/getmaildisabled-account
    ${realPkgs.python3}/bin/python - "$TESTED/home-files/.getmail" <<'PYTHON'
    import ast
    import configparser
    import pathlib
    import sys

    def read_config(name):
        config = configparser.RawConfigParser()
        with open(pathlib.Path(sys.argv[1]) / name) as config_file:
            config.read_file(config_file)
        return config

    primary = read_config("getmailrc")
    assert primary.get("retriever", "imap_search") == "UNSEEN"
    assert ast.literal_eval(primary.get("retriever", "mailboxes")) == ('INBOX."quoted"',)
    assert ast.literal_eval(primary.get("retriever", "password_command")) == ('password-command', 'argument"with-quotes')
    assert primary.get("destination", "type") == "MDA_external"
    assert primary.get("destination", "path") == "/bin/maildrop"
    assert ast.literal_eval(primary.get("destination", "arguments")) == ('--message-from-stdin',)
    assert not primary.getboolean("options", "delete")
    assert not primary.getboolean("options", "read_all")
    assert primary.getint("options", "verbose") == 2
    assert primary.get("filter-1", "type") == "Filter_external"
    assert primary.get("filter-1", "path") == "/bin/true"

    secondary = read_config("getmailhm-account")
    assert ast.literal_eval(secondary.get("retriever", "mailboxes")) == ('INBOX', 'Archive')
    assert ast.literal_eval(secondary.get("retriever", "password_command")) == ('helper', '--account', 'secondary')
    assert secondary.get("retriever", "server") == "imap.native.example.org"
    assert secondary.getint("retriever", "port") == 993
    assert secondary.get("destination", "path") == "/bin/true"
    assert secondary.getboolean("options", "read_all")
    assert secondary.getboolean("options", "delete")
    PYTHON
  '';
}
