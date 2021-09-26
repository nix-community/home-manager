{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    services.lieer.enable = true;

    accounts.email.accounts = {
      "hm@example.com" = {
        flavor = "gmail.com";
        lieer = {
          enable = true;
          sync.enable = true;
        };
        notmuch.enable = true;
      };
    };

    test.stubs.gmailieer = { };

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.service
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.timer

      assertFileContent home-files/.config/systemd/user/lieer-hm-example-com.service \
                        ${./lieer-service-expected.service}
      assertFileContent home-files/.config/systemd/user/lieer-hm-example-com.timer \
                        ${./lieer-service-expected.timer}
    '';
  };
}
