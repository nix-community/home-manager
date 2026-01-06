{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = null; };
    systemd.enable = true;
    settings = {
      theme = "catppuccin-mocha";
      font-size = 10;
    };
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user/app-com.mitchellh.ghostty.service
    serviceOverridesPath=$servicePath.d/overrides.conf

    assertFileExists $serviceOverridesPath
    assertFileContent $serviceOverridesPath \
      ${builtins.toFile "ghostty-service-overrides" ''
        [Unit]
        X-SwitchMethod=keep-old
      ''}

    assertFileContent \
      home-files/.config/ghostty/config \
      ${./example-config-expected}
  '';
}
