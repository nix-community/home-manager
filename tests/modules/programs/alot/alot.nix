{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        primary = true;
        notmuch.enable = true;
        alot = {
          contactCompletion = { };
          extraConfig = ''
            auto_remove_unread = True
            ask_subject = False
            handle_mouse = True
          '';
        };
        imap.port = 993;
      };
    };

    programs.alot = { enable = true; };

    nixpkgs.overlays =
      [ (self: super: { alot = pkgs.writeScriptBin "dummy-alot" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/alot/config
      assertFileContent home-files/.config/alot/config ${./alot-expected.conf}
    '';
  };
}

