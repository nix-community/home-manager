{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      himalaya = {
        enable = true;

        backend = "imap";
        sender = "smtp";
        settings = { email-listing-page-size = 50; };
      };

      folders = {
        inbox = "In";
        sent = "Out";
        drafts = "Drafts";
      };

      imap.port = 995;
      smtp.port = 465;
    };
  };

  programs.himalaya = {
    enable = true;
    settings = { downloads-dir = "/data/download"; };
  };

  test.stubs.himalaya = { };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./himalaya-expected.toml
    }
  '';
}
