{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    targets.genericLinux.enable = true;

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        'export XDG_DATA_DIRS="/nix/var/nix/profiles/default/share:/home/hm-user/.nix-profile/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"'
      assertFileContains \
        home-path/etc/profile.d/hm-session-vars.sh \
        '. "${pkgs.nix}/etc/profile.d/nix.sh"'
    '';
  };
}
