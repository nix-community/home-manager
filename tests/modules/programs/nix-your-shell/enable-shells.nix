{
  lib,
  pkgs,
  realPkgs,
  config,
  ...
}:

{
  programs = {
    nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script =
    let
      nushellConfigDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
    in
    ''
      assertFileExists home-files/.config/fish/config.fish
      assertFileRegex \
        home-files/.config/fish/config.fish \
        '/nix/store/[^/]*-nix-your-shell-[^/]*/bin/nix-your-shell fish | source'

      assertFileExists ${nushellConfigDir}/config.nu
      assertFileRegex \
        ${nushellConfigDir}/config.nu \
        'source /nix/store/[^/]*-nix-your-shell-nushell-config.nu'

      assertFileExists home-files/.zshrc
      assertFileRegex \
        home-files/.zshrc \
        '/nix/store/[^/]*-nix-your-shell-[^/]*/bin/nix-your-shell zsh | source /dev/stdin'
    '';
}
