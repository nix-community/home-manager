{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com".maildir = null;
      hm-account.neomutt.enable = true;
    };

    programs.neomutt.enable = true;

    test.stubs.neomutt = { };

    nmt.script = ''
      assertFileExists home-files/.config/neomutt/neomuttrc
      assertFileContent home-files/.config/neomutt/neomuttrc ${
        ./neomutt-not-primary-expected.conf
      }
    '';
  };
}
