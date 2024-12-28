{ lib, ... }:

{
  programs = {
    vivid = {
      enable = true;
      theme = "test";
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.vivid = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'export LS_COLORS="$(@vivid@/bin/dummy generate test)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      'set -gx LS_COLORS (@vivid@/bin/dummy generate test)'

    assertFileExists home-files/.config/nushell/env.nu
    assertFileContains \
      home-files/.config/nushell/env.nu \
      '"LS_COLORS": (@vivid@/bin/dummy generate test)'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'export LS_COLORS="$(@vivid@/bin/dummy generate test)"'
  '';
}
