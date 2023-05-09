{ lib, ... }:

{
  programs = {
    zellij = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      enableFishIntegration = false;
    };
    bash.enable = true;
    zsh.enable = true;
    fish.enable = true;
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs = {
    zsh = { };
    zellij = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc \
      'eval "$(zellij setup --generate-auto-start bash)"'

    assertFileNotRegex home-files/.zshrc \
      'eval "$(zellij setup --generate-auto-start zsh)"'

    assertFileNotRegex home-files/.config/fish/config.fish '@zellij@'
  '';
}
