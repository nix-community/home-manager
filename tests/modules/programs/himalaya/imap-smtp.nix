{ config, lib, pkgs, ... }:

with lib;

{
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
        settings = {
          folder-listing-page-size = 50;
          email-listing-page-size = 50;
          folder-aliases = {
            inbox = "In2";
            custom = "Custom";
          };
        };
      };
    };
  };

  programs.himalaya = {
    enable = true;
    settings = { email-listing-page-size = 40; };
  };

  test.stubs.himalaya = { };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./imap-smtp-expected.toml
    }
  '';
}
