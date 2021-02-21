{ config, lib, pkgs, ... }:

with lib;

let

  profileDirectory = config.home.profileDirectory;

in {
  options.targets.genericLinux = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable settings that make Home Manager work better on
        GNU/Linux distributions other than NixOS.
      '';
    };

    extraXdgDataDirs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/usr/share" "/usr/local/share" ];
      description = ''
        List of directory names to add to <envar>XDG_DATA_DIRS</envar>.
      '';
    };
  };

  config = mkIf config.targets.genericLinux.enable {
    home.sessionVariables = let
      profiles =
        [ "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default" profileDirectory ];
      dataDirs = concatStringsSep ":"
        (map (profile: "${profile}/share") profiles
          ++ config.targets.genericLinux.extraXdgDataDirs);

      # https://github.com/archlinux/svntogit-packages/blob/packages/ncurses/trunk/PKGBUILD
      # https://salsa.debian.org/debian/ncurses/-/blob/master/debian/rules
      # https://src.fedoraproject.org/rpms/ncurses/blob/main/f/ncurses.spec
      # https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-libs/ncurses/ncurses-6.2-r1.ebuild
      distroTerminfoDirs = concatStringsSep ":" [
        "/etc/terminfo" # debian, fedora, gentoo
        "/lib/terminfo" # debian
        "/usr/share/terminfo" # package default, all distros
      ];
    in {
      XDG_DATA_DIRS = "${dataDirs}\${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS";
      TERMINFO_DIRS =
        "${profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}${distroTerminfoDirs}";
    };

    home.sessionVariablesExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"

      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';

    # We need to source both nix.sh and hm-session-vars.sh as noted in
    # https://github.com/nix-community/home-manager/pull/797#issuecomment-544783247
    programs.bash.initExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"
      . "${profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';

    systemd.user.sessionVariables = {
      NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
    };
  };
}
