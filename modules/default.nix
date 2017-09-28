{ configuration
, pkgs
, lib ? pkgs.stdenv.lib

  # Whether to check that each option has a matching declaration.
, check ? true
}:

with lib;

let

  modules = [
    ./home-environment.nix
    ./manual.nix
    ./misc/gtk.nix
    ./misc/news.nix
    ./misc/pam.nix
    ./programs/bash.nix
    ./programs/beets.nix
    ./programs/browserpass.nix
    ./programs/command-not-found/command-not-found.nix
    ./programs/eclipse.nix
    ./programs/emacs.nix
    ./programs/feh.nix
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/gnome-terminal.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/info.nix
    ./programs/lesspipe.nix
    ./programs/ssh.nix
    ./programs/termite.nix
    ./programs/texlive.nix
    ./programs/vim.nix
    ./programs/zsh.nix
    ./programs/rofi.nix
    ./services/blueman-applet.nix
    ./services/compton.nix
    ./services/dunst.nix
    ./services/gnome-keyring.nix
    ./services/gpg-agent.nix
    ./services/keepassx.nix
    ./services/network-manager-applet.nix
    ./services/owncloud-client.nix
    ./services/random-background.nix
    ./services/redshift.nix
    ./services/screen-locker.nix
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
    config._module.check = check;
  };

  rawModule = lib.evalModules {
    modules = [ configuration ] ++ modules ++ [ pkgsModule ];
  };

  module = showWarnings (
    let
      failed = collectFailed rawModule.config;
      failedStr = concatStringsSep "\n" (map (x: "- ${x}") failed);
    in
      if failed == []
      then rawModule
      else throw "\nFailed assertions:\n${failedStr}"
  );

in

{
  inherit (module) options config;

  activationPackage = module.config.home.activationPackage;

  # For backwards compatibility. Please use activationPackage instead.
  activation-script = module.config.home.activationPackage;

  newsDisplay = rawModule.config.news.display;
  newsEntries =
    sort (a: b: a.time > b.time) (
      filter (a: a.condition) rawModule.config.news.entries
    );
}
