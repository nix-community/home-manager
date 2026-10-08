{ config, ... }:
{
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;

  programs.ghostty = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = null; };

    settings = {
      theme = "catppuccin-mocha";
      font-size = 10;
    };
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user/app-com.mitchellh.ghostty.service
    assertPathNotExists $servicePath

    assertFileContent \
      home-files/.config/ghostty/config \
      ${./example-config-expected}

    assertFileContains home-files/.bashrc \
      '"''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash" ]]; then'
    assertFileContains home-files/.config/fish/config.fish \
      'test -r "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"'
    assertFileContains home-files/.zshrc \
      '"$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration ]]; then'
  '';
}
