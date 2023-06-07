{ config, ... }: {
  programs = {
    rtx = {
      package = config.lib.test.mkStubPackage { name = "rtx"; };
      enable = true;
      enableZshIntegration = true;
    };

    zsh.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.zshrc 'eval "$(/nix/store/.*rtx.*/bin/rtx activate zsh)"'
  '';
}

