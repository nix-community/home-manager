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
    worktrunk.enableZshIntegration = true;
    zsh.enable = true;

  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@worktrunk@/bin/wt config shell init zsh)"'
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
