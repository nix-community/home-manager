{ config, ... }:
{
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
    serviceFile="LaunchAgents/org.nix-community.home.sequoia-keystore.plist"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFileNormalized" ${./sequoia-keystore.plist}
  '';
}
