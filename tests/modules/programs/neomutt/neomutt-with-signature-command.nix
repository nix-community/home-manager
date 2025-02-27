{ pkgs, ... }:

{
  imports = [ ../../accounts/email-test-accounts.nix ];

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
      signature = {
        showSignature = "append";
        command = pkgs.writeScript "signature" "echo This is my signature";
      };
    };
  };

  programs.neomutt = {
    enable = true;
    vimKeys = false;
  };

  nmt.script = ''
    assertFileExists home-files/.config/neomutt/neomuttrc
    assertFileExists home-files/.config/neomutt/hm@example.com
    assertFileContent home-files/.config/neomutt/neomuttrc ${
      ./neomutt-expected.conf
    }
    expectedSignature=$(normalizeStorePaths "home-files/.config/neomutt/hm@example.com")
    assertFileContent "$expectedSignature" ${
      ./hm-example.com-signature-command-expected
    }
  '';
}
