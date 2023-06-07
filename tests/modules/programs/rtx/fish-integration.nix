{ config, ... }: {
  programs = {
    rtx = {
      package = config.lib.test.mkStubPackage { name = "rtx"; };
      enable = true;
      enableFishIntegration = true;
    };

    fish.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.config/fish/config.fish '/nix/store/.*rtx.*/bin/rtx activate fish | source'
  '';
}

