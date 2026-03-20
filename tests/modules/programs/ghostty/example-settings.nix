{ config, ... }:
{
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
  '';
}
