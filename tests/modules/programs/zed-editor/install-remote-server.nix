{ config, ... }:

let
  executableName = "zed-remote-server-stable-57+stable";
in
{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "57"; } // {
      remote_server = config.lib.test.mkStubPackage {
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/${executableName}
        '';
      };
      remoteServerExecutableName = executableName;
    };
    installRemoteServer = true;
  };

  nmt.script = ''
    assertFileExists "home-files/.zed_server/${executableName}"
  '';
}
