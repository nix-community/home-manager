{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "6f866d1acb89fa15cd3b62baa052deae1f685c0c";
    sha256 = "1qr1shhapjn4nnd4k6hml69ri8vgz4l8lakjll5hc516shs9a9nn";
  };

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  };

in

import nmt {
  inherit lib pkgs modules;
  testedAttrPath = [ "home" "activationPackage" ];
  tests = builtins.foldl' (a: b: a // (import b)) { } ([
    ./lib/types
    ./modules/files
    ./modules/home-environment
    ./modules/misc/fontconfig
    ./modules/programs/alacritty
    ./modules/programs/bash
    ./modules/programs/browserpass
    ./modules/programs/fish
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/mbsync
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/readline
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/texlive
    ./modules/programs/tmux
    ./modules/programs/zsh
    ./modules/xresources
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    ./modules/misc/pam
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/firefox
    ./modules/programs/getmail
    ./modules/programs/rofi
    ./modules/services/sxhkd
    ./modules/services/window-managers/i3
    ./modules/systemd
  ]);
}
