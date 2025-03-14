{ config, ... }:

{
  imports = [ ./fusuma-stubs.nix ];

  services.fusuma = {
    enable = true;
    extraPackages = [
      (config.lib.test.mkStubPackage { outPath = "@coreutils@"; })
      (config.lib.test.mkStubPackage { outPath = "@xdotool@"; })
      (config.lib.test.mkStubPackage { outPath = "@xorg.xprop@"; })
    ];
    settings = { };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/fusuma.service \
        ${./expected-service.service}
  '';
}
