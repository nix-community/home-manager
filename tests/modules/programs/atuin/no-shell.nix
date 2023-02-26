{ lib, ... }:

{
  programs = {
    atuin = {
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
    atuin = { };
    bash-preexec = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc 'atuin init zsh'
    assertFileNotRegex home-files/.bashrc 'atuin init bash'
    assertFileNotRegex home-files/.config/fish/config.fish 'atuin init fish'
  '';
}
