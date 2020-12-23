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

    test.asserts.warnings.expected = [''
      lieer is enabled for the following email accounts, but notmuch is not:

          hm@example.com

      Notmuch can be enabled with:

          accounts.email.accounts.hm@example.com.notmuch.enable = true;

      If you have configured notmuch outside of Home Manager, you can suppress this
      warning with:

          programs.lieer.notmuchSetupWarning = false;
    ''];

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.service
      assertFileExists home-files/.config/systemd/user/lieer-hm-example-com.timer

      assertFileContent home-files/.config/systemd/user/lieer-hm-example-com.service \
                        ${
                          pkgs.writeText "lieer-service-expected.service" ''
                            [Service]
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
