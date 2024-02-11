{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        notmuch.enable = true;
        neomutt = {
          enable = true;
          extraConfig = ''
            color status cyan default
          '';
          mailboxName = "someCustomName";
          extraMailboxes = [
            "Sent"
            {
              mailbox = "Junk Email";
              name = "Spam";
              type = "imap";
            }
            { mailbox = "Trash"; }
          ];
        };
        imap.port = 993;
      };
    };

    programs.neomutt = {
      enable = true;
      vimKeys = false;
    };

    test.stubs.neomutt = { };

    nmt.script = ''
      assertFileExists home-files/.config/neomutt/neomuttrc
      assertFileExists home-files/.config/neomutt/hm@example.com
      assertFileContent $(normalizeStorePaths home-files/.config/neomutt/neomuttrc) ${
        ./neomutt-with-imap-type-mailboxes-expected.conf
      }
      assertFileContent home-files/.config/neomutt/hm@example.com ${
        ./hm-example.com-expected
      }

      confFile=$(grep -o \
          '/nix/store/.*-account-command.sh/bin/account-command.sh' \
          $TESTED/home-files/.config/neomutt/neomuttrc)
      assertFileContent "$(normalizeStorePaths "$confFile")" ${
        ./account-command.sh-expected
      }
    '';
  };
}
