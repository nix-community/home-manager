{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    services.lieer.enable = true;

    accounts.email.accounts = {
      "hm@example.com".lieer.enable = true;
      "hm@example.com".lieer.sync.enable = true;
    };

    nixpkgs.overlays = [
      (self: super: {
        gmailieer = pkgs.writeScriptBin "dummy-gmailieer" "" // {
          outPath = "@lieer@";
        };
      })
    ];

    nmt.script = ''
      assertFileExists $home_files/.config/systemd/user/lieer-hm-example-com.service
      assertFileExists $home_files/.config/systemd/user/lieer-hm-example-com.timer

      assertFileContent $home_files/.config/systemd/user/lieer-hm-example-com.service \
                        ${./lieer-service-expected.service}
      assertFileContent $home_files/.config/systemd/user/lieer-hm-example-com.timer \
                        ${./lieer-service-expected.timer}
    '';
  };
}
