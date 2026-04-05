{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableFishIntegration = false;
    fish.enable = true;
  };

  test.stubs.worktrunk = { };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileNotRegex \
      home-files/.config/fish/config.fish \
      '@worktrunk@/bin/wt config shell init fish | source'
  '';
}
