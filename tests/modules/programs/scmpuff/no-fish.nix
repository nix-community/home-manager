{ lib, ... }:

{
  programs = {
    scmpuff = {
      enable = true;
      enableFishIntegration = false;
    };
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.scmpuff = { };

  nmt.script = ''
    assertFileNotRegex home-files/.config/fish/config.fish '@scmpuff@'
  '';
}
