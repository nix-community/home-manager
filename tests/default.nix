{ nmt ? builtins.fetchTarball "https://github.com/kloenk/nmt/archive/master.tar.gz", nixpkgs ? <nixpkgs>, pkgs ? import nixpkgs { system = builtins.currentSystem; }, lib ? import ../modules/lib/stdlib-extended.nix pkgs.lib, system ? builtins.currentSystem}:

let
  testString = re: x: builtins.match re x != null;

  modules = import ../modules/modules.nix nixpkgs {
    inherit pkgs lib;
    check = false;
  } ++ [
    # Fix impurities. Without these some of the user's environment
    # will leak into the tests through `builtins.getEnv`.
    {
      manual.manpages.enable = false;
      xdg.enable = true;
      home.username = "hm-user";
      home.homeDirectory = "/home/hm-user";
    }
    # nmt settings
    ({ config, ...} : {
      nmt.startUpCommands = let
        home = config.home.activationPackage;
      in ''
        out=$out/${config.nmt.name}
        mkdir -p $out
        home_files="${home}/home-files"
        home_path="${home}/home-path"
      '';
    })
  ];

  tests =  ((if nmt ? lib then nmt.lib.nmt else import nmt) {
    inherit modules lib pkgs;
    tests = builtins.foldl' (a: b: a // (import b)) {} ([
      ./modules/programs/git
      ./modules/files
      ./modules/home-environment
      ./modules/misc/fontconfig
      ./modules/programs/alacritty 
      ./modules/programs/alot
      ./modules/programs/aria2
      ./modules/programs/bash
      ./modules/programs/dircolors
      ./modules/programs/fish
      ./modules/programs/gpg
      ./modules/programs/i3status
      ./modules/programs/kakoune
      ./modules/programs/lf
      ./modules/programs/lieer
      ./modules/programs/mbsync
      ./modules/programs/neomutt
      ./modules/programs/newsboat
      ./modules/programs/qutebrowser
      ./modules/programs/readline
      ./modules/programs/ssh
      ./modules/programs/starship
      ./modules/programs/texlive
      ./modules/programs/tmux
      ./modules/programs/zsh
      ./modules/xresources
    ] ++ lib.optionals (testString "[a-z0-9_]*-linux" system) [
    ./modules/misc/debug
    ./modules/misc/pam
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/firefox
    ./modules/programs/getmail
    ./modules/services/lieer
    ./modules/programs/rofi
    ./modules/services/polybar
    ./modules/services/sxhkd
    ./modules/services/window-managers/i3
    ./modules/systemd
    ./modules/targets
  ] ++ lib.optionals ((testString "armv.*-linux" system) != true) [
    ./modules/programs/browserpass
    ./modules/programs/git
  ]);
  });
in {
  inherit (tests) all list run;
}
