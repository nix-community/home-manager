{ lib, ... }:

{
  programs = {
    zellij = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableFishAutoStart = true;
      enableFishCompletions = true;
      autoStartAttachIfSessionExists = true;
      autoStartExitShellOnZellijExit = true;
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
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@zellij@/bin/dummy setup --generate-auto-start bash)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@zellij@/bin/dummy setup --generate-auto-start zsh)"'

    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      'eval (@zellij@/bin/dummy setup --generate-auto-start fish | string collect)'
    assertFileContains \
      home-files/.config/fish/config.fish \
      'eval (@zellij@/bin/dummy setup --generate-completion fish | string collect)'
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains \
      home-path/etc/profile.d/hm-session-vars.sh \
      'export ZELLIJ_AUTO_ATTACH="true"'
    assertFileContains \
      home-path/etc/profile.d/hm-session-vars.sh \
      'export ZELLIJ_AUTO_EXIT="true"'
  '';
}
