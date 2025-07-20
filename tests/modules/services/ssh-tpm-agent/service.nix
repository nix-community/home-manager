{ config, ... }:

{
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
      ExecStart=@ssh-tpm-agent@/bin/dummy -l %t/ssh-tpm-agent.sock
      PassEnvironment=SSH_AGENT_PID
      SuccessExitStatus=2
      Type=simple

      [Unit]
      After=ssh-tpm-agent.socket
      Description=ssh-tpm-agent service
      Documentation=https://github.com/Foxboron/ssh-tpm-agent
      RefuseManualStart=true
      Requires=ssh-tpm-agent.socket
    ''}

    assertFileContent $socketFile ${builtins.toFile "expected-socket" ''
      [Install]
      WantedBy=sockets.target

      [Socket]
      DirectoryMode=0700
      ListenStream=%t/ssh-tpm-agent.sock
      RuntimeDirectory=ssh-tpm-agent
      Service=ssh-tpm-agent.service
      SocketMode=0600

      [Unit]
      Description=SSH TPM agent socket
      Documentation=https://github.com/Foxboron/ssh-tpm-agent
    ''}
  '';
}
