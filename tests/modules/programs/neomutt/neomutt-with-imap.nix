{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        neomutt = {
          enable = true;
          mailboxType = "imap";
          extraConfig = ''
            color status cyan default
          '';
        };
        imap.port = 993;
      };
    };

    programs.neomutt.enable = true;

    test.stubs.neomutt = { };

    nmt.script = ''
      assertFileExists home-files/.config/neomutt/neomuttrc
      assertFileExists home-files/.config/neomutt/hm@example.com
      assertFileContent $(normalizeStorePaths home-files/.config/neomutt/neomuttrc) ${
        ./neomutt-with-imap-expected.conf
      }
      assertFileContent home-files/.config/neomutt/hm@example.com ${
        ./hm-example.com-imap-expected.conf
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
