{ lib, ... }:

{
  programs = {
    scmpuff.enable = true;
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@scmpuff@/bin/scmpuff init --shell=fish | source'
  '';
}
