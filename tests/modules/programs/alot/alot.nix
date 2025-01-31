{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      notmuch.enable = true;
      alot = {
        contactCompletion = { };
        extraConfig = ''
          auto_remove_unread = True
          ask_subject = False
          handle_mouse = True
        '';
      };
      imap.port = 993;
    };
  };

  programs.alot = { enable = true; };

  nmt.script = ''
    assertFileExists home-files/.config/alot/config
    assertFileContent home-files/.config/alot/config ${./alot-expected.conf}
  '';
}

