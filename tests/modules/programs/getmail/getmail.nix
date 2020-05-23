{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        getmail = {
          enable = true;
          mailboxes = [ "INBOX" "Sent" "Work" ];
          destinationCommand = "/bin/maildrop";
          delete = false;
        };
        imap.port = 993;
      };
    };

    nmt.script = ''
      assertFileExists $home_files/.getmail/getmailhm@example.com
      assertFileContent $home_files/.getmail/getmailhm@example.com ${
        ./getmail-expected.conf
      }
    '';
  };
}
