{ lib, ... }:

{
  programs = {
    zellij.enable = true;
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.zellij = { };

  nmt.script = ''
    assertFileNotRegex home-files/.config/fish/config.fish '@zellij@'
  '';
}
