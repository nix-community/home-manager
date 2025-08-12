{ config, ... }:

{
  services.ssh-agent.enable = true;
  services.ssh-tpm-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@ssh-tpm-agent@"; };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/ssh-tpm-agent.service
    socketFile=home-files/.config/systemd/user/ssh-tpm-agent.socket

    assertFileExists $serviceFile
    assertFileExists $socketFile

    assertFileContent $serviceFile ${builtins.toFile "expected-service" ''
      [Service]
      Environment=SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock
      ExecStart=@ssh-tpm-agent@/bin/dummy -A %t/ssh-agent
      SuccessExitStatus=2
      Type=simple

      [Unit]
      After=ssh-tpm-agent.socket
      After=ssh-agent.service
      BindsTo=ssh-agent.service
      Description=ssh-tpm-agent service
      Documentation=https://github.com/Foxboron/ssh-tpm-agent
      Requires=ssh-tpm-agent.socket
    ''}

    assertFileContent $socketFile ${builtins.toFile "expected-socket" ''
      [Install]
      WantedBy=sockets.target

      [Socket]
      ListenStream=%t/ssh-tpm-agent.sock
      Service=ssh-tpm-agent.service
      SocketMode=0600

      [Unit]
      Description=SSH TPM agent socket
      Documentation=https://github.com/Foxboron/ssh-tpm-agent
    ''}
  '';
}
