{ config, lib, pkgs, ... }:

with lib;

{
  # imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      primary = true;
      address = "hm@example.com";
      userName = "home.manager";
      realName = "H. M. Test";
      passwordCommand = "password-command";
      imap = {
        host = "imap.example.com";
        port = 143;
        tls = { enable = false; };
      };
      smtp = {
        host = "smtp.example.com";
        port = 465;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      folders = {
        inbox = "In";
        sent = "Out";
        drafts = "D";
      };
      himalaya = {
        enable = true;
        settings = { email-listing-page-size = 50; };
      };
    };
  };

  programs.himalaya = { enable = true; };

  test.stubs.himalaya = { };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./imap-smtp-expected.toml
    }
  '';
}
