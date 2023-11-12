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
      folders = { trash = "Deleted"; };
      msmtp.enable = true;
      himalaya = {
        enable = true;
        settings = { sendmail-cmd = "msmtp"; };
      };
    };
  };

  programs.himalaya = {
    enable = true;
    settings = { email-listing-page-size = 50; };
  };

  test.stubs.himalaya = { };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./maildir-sendmail-expected.toml
    }
  '';
}
