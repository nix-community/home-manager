{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.thunderbird = {
      enable = true;
      profiles.testUser.accounts."some.one@somewhere.net".filters = fx:
        with fx; {
          "some filter" = {
            condition = all [ "subject,contains,hello" ];
            actions = [ mark-read (move-to (imap-folder "some/folder")) ];
          };
        };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.thunderbird/testUser/ImapMail/mail.somewhere.net/msgFilterRules.dat \
        ${./message-filters-expected.dat}
    '';
  };
}
