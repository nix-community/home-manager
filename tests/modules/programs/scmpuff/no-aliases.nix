{ lib, ... }:

{
  programs = {
    scmpuff.enable = true;
    scmpuff.enableAliases = false;
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.scmpuff = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@scmpuff@/bin/scmpuff init --shell=bash --aliases=false)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@scmpuff@/bin/scmpuff init --shell=zsh --aliases=false)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@scmpuff@/bin/scmpuff init --shell=fish --aliases=false | source'
  '';
}
