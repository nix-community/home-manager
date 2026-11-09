{ config, ... }:
{
  home.enableNixpkgsReleaseCheck = false;

  services.sequoia-keystore = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "sequoia-keystore-server";
      outPath = "@sequoia-keystore-server@";
    };
    sequoiaHome = "/home/hm-user/.local/share/sequoia";
    home = "/home/hm-user/.local/share/sequoia/keystore";
    ephemeral = false;
    lib = "/home/hm-user/.local/libexec/sequoia";
    extraArgs = [ "--debug" ];
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/sequoia-keystore.service"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFileNormalized" ${./sequoia-keystore.service}
  '';
}
