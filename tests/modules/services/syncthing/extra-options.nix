{ lib, pkgs, ... }:

lib.mkMerge [
  {
    test.stubs.writers = {
      extraAttrs.writeBash = (name: fn: "@syncthing-wrapper@");
    };

    services.syncthing = {
      enable = true;
      extraOptions = [
        "-foo"
        ''-bar "baz"''
      ];
    };
  }

  (lib.mkIf pkgs.stdenv.isLinux {
    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/syncthing.service
      assertFileContains home-files/.config/systemd/user/syncthing.service \
      "ExecStart=@syncthing@/bin/syncthing serve --no-browser --no-restart --no-upgrade '--gui-address=127.0.0.1:8384' -foo '-bar \"baz\"'"
    '';
  })

  (lib.mkIf pkgs.stdenv.isDarwin {
    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.syncthing.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./expected-agent.plist}
    '';
  })
]
