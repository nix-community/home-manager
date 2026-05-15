{ config, ... }:

{
  home.sessionVariables.SSH_ASKPASS = "/run/current-system/sw/bin/ssh-askpass";

  services.ssh-tpm-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@ssh-tpm-agent@"; };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/ssh-tpm-agent.service

    assertFileExists $serviceFile

    assertFileContent $serviceFile ${builtins.toFile "expected-service" ''
      [Service]
      Environment=SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock
      Environment=SSH_ASKPASS=/run/current-system/sw/bin/ssh-askpass
      ExecStart=@ssh-tpm-agent@/bin/dummy
      SuccessExitStatus=2
      Type=simple

      [Unit]
      After=ssh-tpm-agent.socket
      Description=ssh-tpm-agent service
      Documentation=https://github.com/Foxboron/ssh-tpm-agent
      Requires=ssh-tpm-agent.socket
    ''}
  '';
}
