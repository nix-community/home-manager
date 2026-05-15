{ config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
  };
  remoteControlPackage = config.lib.test.mkStubPackage {
    name = "codex-remote-control";
  };
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    remoteControl = {
      enable = true;
      package = remoteControlPackage;
      listen = "unix://";
      environment = {
        RUST_LOG = "codex_app_server=info";
      };
      environmentFile = "/run/secrets/codex-remote-control.env";
      extraArgs = [
        "--analytics-default-enabled"
      ];
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/codex-remote-control.service
    assertFileExists "$serviceFile"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileContent "$serviceFileNormalized" ${./remote-control-service.service}
  '';
}
