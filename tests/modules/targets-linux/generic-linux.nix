{ config, lib, pkgs, ... }:

with lib;

let
  expectedXdgDataDirs = concatStringsSep ":" [
    "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
    "/home/hm-user/.nix-profile/share"
    "/usr/share/ubuntu"
    "/usr/local/share"
    "/usr/share"
    "/var/lib/snapd/desktop"
    "/foo"
  ];

in {
  config = {
    targets.genericLinux.enable = true;

    xdg.systemDirs.data = [ "/foo" ];

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContains $envFile \
        'XDG_DATA_DIRS=${expectedXdgDataDirs}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}'
      assertFileContains $envFile \
        'TERMINFO_DIRS=/home/hm-user/.nix-profile/share/terminfo:$TERMINFO_DIRS''${TERMINFO_DIRS:+:}/etc/terminfo:/lib/terminfo:/usr/share/terminfo'

      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        '. "${pkgs.nix}/etc/profile.d/nix.sh"'

      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        'export TERM="$TERM"'
    '';
  };
}
