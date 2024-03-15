{ config, ... }: {
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      enableZshIntegration = true;
    };

    zsh.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.zshrc 'eval "$(/nix/store/.*mise.*/bin/mise activate zsh)"'
  '';
}

