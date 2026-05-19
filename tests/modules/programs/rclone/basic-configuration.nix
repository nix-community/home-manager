{ lib, pkgs, ... }:

lib.mkMerge [
  {
    programs.rclone = {
      enable = true;
      remotes.myremote.config.type = "local";
    };
  }

  (lib.mkIf pkgs.stdenv.isLinux {
    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/rclone-config.service
    '';
  })

  (lib.mkIf pkgs.stdenv.isDarwin {
    nmt.script = ''
      assertFileExists LaunchAgents/org.nix-community.home.rclone-config.plist
    '';
  })
]
