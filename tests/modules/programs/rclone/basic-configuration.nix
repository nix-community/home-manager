{ lib, pkgs, ... }:

lib.mkMerge [
  {
    programs.rclone = {
      enable = true;
      remotes.myremote.config.type = "local";
    };
  }

  (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/rclone-config.service
    '';
  })

  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    nmt.script = ''
      assertFileExists LaunchAgents/org.nix-community.home.rclone-config.plist
    '';
  })
]
