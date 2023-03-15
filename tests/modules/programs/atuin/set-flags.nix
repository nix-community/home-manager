{ lib, ... }:

{
  programs = {
    atuin.enable = true;
    atuin.flags = [ "--disable-ctrl-r" "--disable-up-arrow" ];
    bash = {
      enable = true;
      enableCompletion = false;
    };
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
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      "eval \"\$(@atuin@/bin/atuin init bash '--disable-ctrl-r' '--disable-up-arrow')\""

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      "eval \"\$(@atuin@/bin/atuin init zsh '--disable-ctrl-r' '--disable-up-arrow')\""
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      "@atuin@/bin/atuin init fish --disable-ctrl-r --disable-up-arrow | source"
  '';
}
