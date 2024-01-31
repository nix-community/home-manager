{ config, ... }: {
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      enableBashIntegration = true;
    };

    bash.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.bashrc 'eval "$(/nix/store/.*mise.*/bin/mise activate bash)"'
  '';
}

