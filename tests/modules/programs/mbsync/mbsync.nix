{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.mbsync = {
      enable = true;
      groups.inboxes = {
        "hm@example.com" = [ "Inbox1" "Inbox2" ];
        hm-account = [ "Inbox" ];
      };
    };

    accounts.email.accounts = {
      "hm@example.com".mbsync = { enable = true; };

      hm-account.mbsync = { enable = true; };
    };

    nmt.script = ''
      assertFileExists $home_files/.mbsyncrc
      assertFileContent $home_files/.mbsyncrc ${./mbsync-expected.conf}
    '';
  };
}
