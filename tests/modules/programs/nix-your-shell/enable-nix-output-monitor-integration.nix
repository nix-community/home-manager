{
  lib,
  realPkgs,
  ...
}:

{
  programs = {
    nix-output-monitor.enable = true;
    nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNixOutputMonitorIntegration = true;
    };
    fish.enable = true;
    zsh.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex \
      home-files/.config/fish/config.fish \
      '/nix/store/[^/]*-nix-your-shell-[^/]*/bin/nix-your-shell --nom fish | source'

    assertFileExists home-files/.zshrc
    assertFileRegex \
      home-files/.zshrc \
      '/nix/store/[^/]*-nix-your-shell-[^/]*/bin/nix-your-shell --nom zsh | source /dev/stdin'
  '';
}
