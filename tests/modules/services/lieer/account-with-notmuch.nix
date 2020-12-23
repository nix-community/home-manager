{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.notmuch.enable = true;
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

    nixpkgs.overlays = [
      (self: super: {
        gmailieer = pkgs.writeScriptBin "dummy-gmailieer" "" // {
          outPath = "@lieer@";
        };

        notmuch = pkgs.writeScriptBin "dummy-notmuch" "";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.service
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.timer

      assertFileContent home-files/.config/systemd/user/lieer-hm-example-com.service \
                        ${
                          pkgs.writeText "lieer-service-expected.service" ''
                            [Service]
                            Environment=NOTMUCH_CONFIG=/home/hm-user/.config/notmuch/notmuchrc
                            ExecStart=@lieer@/bin/gmi sync
                            Type=oneshot
                            WorkingDirectory=/home/hm-user/Mail/hm@example.com

                            [Unit]
                            ConditionPathExists=/home/hm-user/Mail/hm@example.com/.gmailieer.json
                            Description=lieer Gmail synchronization for hm@example.com
                          ''
                        }
      assertFileContent home-files/.config/systemd/user/lieer-hm-example-com.timer \
                        ${./lieer-service-expected.timer}
    '';
  };
}
