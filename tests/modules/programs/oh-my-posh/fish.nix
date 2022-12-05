{ lib, ... }:

{
  programs = {
    fish.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  # Needed to avoid error with dummy fish package.
  xdg.dataFile."fish/home-manager_generated_completions".source =
    lib.mkForce (builtins.toFile "empty" "");

  test.stubs.oh-my-posh = { };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      '/bin/oh-my-posh init fish --config'
  '';
}
