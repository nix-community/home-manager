{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.settings = {
      skip-shell-integration-prompt = true;
      post-start = {
        copy = "wt step copy-ignored";
      };
    };
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.config/worktrunk/config.toml
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      'skip-shell-integration-prompt = true'
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      '[post-start]'
    assertFileContains \
      home-files/.config/worktrunk/config.toml \
      'copy = "wt step copy-ignored"'
  '';
}
