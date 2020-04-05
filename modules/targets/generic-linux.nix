{ config, lib, pkgs, ... }:

with lib;

let

  profileDirectory = config.home.profileDirectory;

in {
  options.targets.genericLinux.enable = mkEnableOption "" // {
    description = ''
      Whether to enable settings that make Home Manager work better on
      GNU/Linux distributions other than NixOS.
    '';
  };

  config = mkIf config.targets.genericLinux.enable {
    home.sessionVariables = let
      profiles = [ "/nix/var/nix/profiles/default" profileDirectory ];
      dataDirs =
        concatStringsSep ":" (map (profile: "${profile}/share") profiles);
    in { XDG_DATA_DIRS = "${dataDirs}\${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"; };

    home.sessionVariablesExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"
    '';

    # We need to source both nix.sh and hm-session-vars.sh as noted in
    # https://github.com/rycee/home-manager/pull/797#issuecomment-544783247
    programs.bash.initExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"
      . "${profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';

    systemd.user.sessionVariables = {
      NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
    };
  };
}
