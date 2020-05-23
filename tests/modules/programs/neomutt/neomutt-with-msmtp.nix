{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        primary = true;
        msmtp.enable = true;
        neomutt = {
          enable = true;
          extraConfig = ''
            color status cyan default
          '';
        };
        imap.port = 993;
      };
    };

    programs.neomutt.enable = true;

    nixpkgs.overlays =
      [ (self: super: { neomutt = pkgs.writeScriptBin "dummy-neomutt" ""; }) ];

    nmt.script = ''
      assertFileExists $home_files/.config/neomutt/neomuttrc
      assertFileExists $home_files/.config/neomutt/hm@example.com
      assertFileContent $home_files/.config/neomutt/neomuttrc ${
        ./neomutt-expected.conf
      }
      assertFileContent $home_files/.config/neomutt/hm@example.com ${
        ./hm-example.com-msmtp-expected.conf
      }
    '';
  };
}
