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
        };
        imap.port = 993;
      };
    };

    programs.neomutt = {
      enable = true;
      vimKeys = false;

      binds = [
        {
          action = "complete-query";
          key = "<Tab>";
          map = "editor";
        }
        {
          action = "sidebar-prev";
          key = "\\Cp";
          map = [ "index" "pager" ];
        }
      ];

      macros = [
        {
          action = "<save-message>?<tab>";
          key = "s";
          map = "index";
        }
        {
          action = "<change-folder>?<change-dir><home>^K=<enter><tab>";
          key = "c";
          map = [ "index" "pager" ];
        }
      ];
    };

    test.stubs.neomutt = { };

    test.asserts.warnings.expected = [
      "Specifying 'programs.neomutt.(binds|macros).map' as a string is deprecated, use a list of strings instead. See https://github.com/nix-community/home-manager/pull/1885."
    ];

    nmt.script = ''
      assertFileExists home-files/.config/neomutt/neomuttrc
      assertFileExists home-files/.config/neomutt/hm@example.com
      assertFileContent home-files/.config/neomutt/neomuttrc ${
        ./neomutt-with-binds-expected.conf
      }
      assertFileContent home-files/.config/neomutt/hm@example.com ${
        ./hm-example.com-expected
      }
    '';
  };
}
