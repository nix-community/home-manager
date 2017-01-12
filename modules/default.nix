{ configuration
, pkgs
, lib ? pkgs.stdenv.lib
}:

let

  modules = [
    ./home-environment.nix
    ./programs/bash.nix
    ./programs/beets.nix
    ./programs/eclipse.nix
    ./programs/emacs.nix
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/gnome-terminal.nix
    ./programs/lesspipe.nix
    ./programs/texlive.nix
    ./services/dunst.nix
    ./services/gnome-keyring.nix
    ./services/gpg-agent.nix
    ./services/keepassx.nix
    ./services/network-manager-applet.nix
    ./services/random-background.nix
    ./services/taffybar.nix
    ./services/tahoe-lafs.nix
    ./services/udiskie.nix
    ./services/xscreensaver.nix
    ./systemd.nix
    ./xresources.nix
    ./xsession.nix
  ];

  pkgsModule = {
    config._module.args.pkgs = lib.mkForce pkgs;
  };

  module = lib.evalModules {
    modules = [ configuration ] ++ modules ++ [ pkgsModule ];
  };

in

{
  inherit (module) options config;

  activation-script = module.config.home.activationPackage;
  home-path = module.config.home.path;
}
