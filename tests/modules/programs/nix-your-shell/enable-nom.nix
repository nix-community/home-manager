{ pkgs, config, ... }:

{
  programs = {
    nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableNom = true;
    };
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    nix-your-shell = { };
    nushell = { };
    zsh = { };
  };

  nmt.script = let
    nushellConfigDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "home-files/Library/Application Support/nushell"
    else
      "home-files/.config/nushell";
  in ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@nix-your-shell@/bin/nix-your-shell --nom fish | source'

    assertFileExists ${nushellConfigDir}/config.nu
    assertFileContains \
      ${nushellConfigDir}/config.nu \
      'source ${config.xdg.cacheHome}/nix-your-shell/init.nu'

    assertFileExists ${nushellConfigDir}/env.nu
    assertFileContains \
      ${nushellConfigDir}/env.nu \
      '@nix-your-shell@/bin/nix-your-shell --nom nu | save --force ${config.xdg.cacheHome}/nix-your-shell/init.nu'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      '@nix-your-shell@/bin/nix-your-shell --nom zsh | source /dev/stdin'
  '';
}
