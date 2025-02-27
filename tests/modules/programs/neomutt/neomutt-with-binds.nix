{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      notmuch.enable = true;
      neomutt = {
        enable = true;
        extraConfig = ''
          color status cyan default
        '';
      };
      imap.port = 993;
    };
  };

  programs.neomutt = {
    enable = true;
    vimKeys = false;

    binds = [
      {
        action = "complete-query";
        key = "<Tab>";
        map = [ "editor" ];
      }
      {
        action = "sidebar-prev";
        key = "\\Cp";
        map = [ "index" "pager" ];
      }
    ];

    macros = [
      {
        action = "<save-message>?<tab>";
        key = "s";
        map = [ "index" ];
      }
      {
        action = "<change-folder>?<change-dir><home>^K=<enter><tab>";
        key = "c";
        map = [ "index" "pager" ];
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileExists home-files/.config/neomutt/hm@example.com
    assertFileContent home-files/.config/neomutt/neomuttrc ${
      ./neomutt-with-binds-expected.conf
    }
    assertFileContent home-files/.config/neomutt/hm@example.com ${
      ./hm-example.com-expected
    }
  '';
}
