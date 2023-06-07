{ config, ... }: {
  programs = {
    rtx = {
      package = config.lib.test.mkStubPackage { name = "rtx"; };
      enable = true;
      enableBashIntegration = true;
    };

    bash.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.bashrc 'eval "$(/nix/store/.*rtx.*/bin/rtx activate bash)"'
  '';
}

