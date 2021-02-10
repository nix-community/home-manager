{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    targets.genericLinux = {
      enable = true;
      extraXdgDataDirs = [ "/foo" ];
    };

    nmt.script = ''
      hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $hmEnvFile
      assertFileContains $hmEnvFile \
        'export XDG_DATA_DIRS="''${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share:/home/hm-user/.nix-profile/share:/foo''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"'
      assertFileContains $hmEnvFile \
        '. "${pkgs.nix}/etc/profile.d/nix.sh"'

      assertFileContains $hmEnvFile \
        'export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:$TERMINFO_DIRS''${TERMINFO_DIRS:+:}/etc/terminfo:/lib/terminfo:/usr/share/terminfo"'
      assertFileContains $hmEnvFile \
        'export TERM="$TERM"'

      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContains $envFile \
        'XDG_DATA_DIRS=''${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share:/home/hm-user/.nix-profile/share:/foo''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS'
    '';
  };
}
