{ lib, ... }:

{
  programs = {
    zellij = {
      enable = true;
      enableFishIntegration = true;
    };
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.zellij = { };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      'eval (zellij setup --generate-auto-start fish | string collect)'
  '';
}
