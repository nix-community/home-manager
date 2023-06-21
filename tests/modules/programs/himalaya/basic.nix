{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      imap.port = 993;
      smtp.port = 465;
      himalaya.enable = true;
      himalaya.backend = test.asserts.warnings.expected;
      himalaya.sender = test.asserts.warnings.expected;
    };
  };

  programs.himalaya = { enable = true; };

  test.stubs.himalaya = { };

  nmt.script = ''
    assertFileExists home-files/.config/himalaya/config.toml
    assertFileContent home-files/.config/himalaya/config.toml ${
      ./basic-expected.toml
    }
  '';
}
