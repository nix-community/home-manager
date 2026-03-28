{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableFishIntegration = true;
    fish.enable = true;
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '@worktrunk@/bin/wt config shell init fish | source'
  '';
}
