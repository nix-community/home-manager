{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.mbsync = {
      enable = true;
      # programs.mbsync.groups and
      # accounts.email.accounts.<name>.mbsync.groups should NOT be used at the
      # same time.
      # If they are, then the new version will take precendence.
      groups.inboxes = {
        "hm@example.com" = [ "Inbox1" "Inbox2" ];
        hm-account = [ "Inbox" ];
      };
    };

    accounts.email.accounts = {
      "hm@example.com".mbsync = {
        enable = true;
        groups.inboxes = {
          channels = {
            inbox1 = {
              masterPattern = "Inbox1";
              slavePattern = "Inboxes";
            };
            inbox2 = {
              masterPattern = "Inbox2";
              slavePattern = "Inboxes";
            };
          };
        };
      };

      hm-account.mbsync = {
        enable = true;
        groups.hm-account = {
          channels.earlierPatternMatch = {
            masterPattern = "Label";
            slavePattern = "SomethingUnderLabel";
            patterns = [
              "ThingUnderLabel"
              "!NotThisMaildirThough"
              ''"[Weird] Label?"''
            ];
          };
          channels.inbox = {
            masterPattern = "Inbox";
            slavePattern = "Inbox";
          };
          channels.strangeHostBoxName = {
            masterPattern = "[Weird]/Label Mess";
            slavePattern = "[AnotherWeird]/Label";
          };
          channels.patternMatch = {
            masterPattern = "Label";
            slavePattern = "SomethingUnderLabel";
            patterns = [
              "ThingUnderLabel"
              "!NotThisMaildirThough"
              ''"[Weird] Label?"''
            ];
          };
        };
        # No group should be printed.
        groups.emptyGroup = { };
        # Group should be printed, but left with default channels.
        groups.emptyChannels = {
          channels.empty1 = { };
          channels.empty2 = { };
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.mbsyncrc
      assertFileContent home-files/.mbsyncrc ${./mbsync-expected.conf}
    '';
  };
}
