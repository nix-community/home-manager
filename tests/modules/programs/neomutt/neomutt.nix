{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    home.username = "hm-user";
    home.homeDirectory = "/home/hm-user";
    xdg.configHome = mkForce "/home/hm-user/.config";
    xdg.cacheHome = mkForce "/home/hm-user/.cache";

    accounts.email.accounts = {
      "hm@example.com" = {
        primary = true;
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
    };

    nixpkgs.overlays =
      [ (self: super: { neomutt = pkgs.writeScriptBin "dummy-neomutt" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/neomutt/neomuttrc
      assertFileExists home-files/.config/neomutt/hm@example.com
      assertFileContent home-files/.config/neomutt/neomuttrc ${
        ./neomutt-expected.conf
      }
      assertFileContent home-files/.config/neomutt/hm@example.com ${
        ./hm-example.com-expected
      }
    '';
  };
}
