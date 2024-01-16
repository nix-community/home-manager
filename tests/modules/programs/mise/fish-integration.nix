{ config, ... }: {
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      enableFishIntegration = true;
    };

    fish.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.config/fish/config.fish '/nix/store/.*mise.*/bin/mise activate fish | source'
  '';
}

