{ config, pkgs, ... }:

{
  services.signaturepdf = {
    enable = true;
    port = 9494;
    extraConfig = { upload_max_filesize = "24M"; };
  };

  test.stubs = {
    signaturepdf = { outPath = "/signaturepdf"; };
    xdg-utils = { };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/signaturepdf.service \
      ${./basic-configuration.service}

    assertFileContent \
      home-path/share/applications/signaturepdf.desktop \
      ${./basic-configuration.desktop}
  '';
}
