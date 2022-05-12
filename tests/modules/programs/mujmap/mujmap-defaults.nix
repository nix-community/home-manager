{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.mujmap.enable = true;
    programs.mujmap.package = config.lib.test.mkStubPackage { };

    accounts.email.accounts."hm@example.com" = {
      jmap.host = "example.com";
      mujmap.enable = true;
      notmuch.enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/Mail/hm@example.com/mujmap.toml
      assertFileContent home-files/Mail/hm@example.com/mujmap.toml ${
        ./mujmap-defaults-expected.toml
      }
    '';
  };
}
