{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  programs.neverest = {
    enable = true;
    accounts = {
      "imap-maildir" = {
        left = {
          backend = "imap";
          name = "hm@example.com";
          settings = { backend.port = 993; };
        };
        right = {
          backend = "maildir";
          name = "hm@example.com";
        };
        settings = { left.backend.port = 143; };
      };
    };
  };

  test.stubs.neverest = { };

  nmt.script = ''
    assertFileExists home-files/.config/neverest/config.toml
    assertFileContent home-files/.config/neverest/config.toml ${
      ./basic-expected.toml
    }
  '';
}
