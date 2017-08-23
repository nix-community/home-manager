{ configuration
, pkgs
, lib ? pkgs.stdenv.lib
}:

with lib;

let

  modules = [
    ./home-environment.nix
    ./manual.nix
    ./misc/gtk.nix
    ./misc/pam.nix
    ./programs/bash.nix
    ./programs/beets.nix
    ./programs/browserpass.nix
    ./programs/eclipse.nix
    ./programs/emacs.nix
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/gnome-terminal.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/info.nix
    ./programs/lesspipe.nix
    ./programs/oh-my-zsh.nix
    ./programs/ssh.nix
    ./programs/termite.nix
    ./programs/texlive.nix
    ./programs/zsh.nix
    ./services/dunst.nix
    ./services/gnome-keyring.nix
    ./services/gpg-agent.nix
    ./services/keepassx.nix
    ./services/network-manager-applet.nix
    ./services/random-background.nix
    ./services/redshift.nix
    ./services/syncthing.nix
    ./services/taffybar.nix
    ./services/tahoe-lafs.nix
    ./services/udiskie.nix
    ./services/xscreensaver.nix
    ./systemd.nix
    ./xresources.nix
    ./xsession.nix
    <nixpkgs/nixos/modules/misc/assertions.nix>
    <nixpkgs/nixos/modules/misc/meta.nix>
  ];

  collectFailed = cfg:
    map (x: x.message) (filter (x: !x.assertion) cfg.assertions);

  showWarnings = res:
    let
      f = w: x: builtins.trace "[1;31mwarning: ${w}[0m" x;
    in
      fold f res res.config.warnings;

  pkgsModule = {
    config._module.args.pkgs = lib.mkForce pkgs;
    config._module.args.baseModules = modules;
  };

  module = showWarnings (
    let
      mod = lib.evalModules {
        modules = [ configuration ] ++ modules ++ [ pkgsModule ];
      };

      failed = collectFailed mod.config;

      failedStr = concatStringsSep "\n" (map (x: "- ${x}") failed);
    in
      if failed == []
      then mod
      else throw "\nFailed assertions:\n${failedStr}"
  );

in

{
  inherit (module) options config;

  activation-script = module.config.home.activationPackage;
  home-path = module.config.home.path;
}
