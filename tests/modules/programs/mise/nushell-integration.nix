{ config, ... }:
{
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage {
        name = "mise";
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/mise
          chmod +x $out/bin/mise
        '';
      };
      enable = true;
      enableNushellIntegration = true;
    };

    nushell.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.config/nushell/config.nu \
      'use \/nix\/store\/.*-mise-nushell-config.nu'
  '';
}
