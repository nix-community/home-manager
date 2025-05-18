{ config, ... }:

{
  services.yubikey-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@yubikey-agent@"; };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/yubikey-agent.service
    socketFile=home-files/.config/systemd/user/yubikey-agent.socket

    assertFileExists $serviceFile
    assertFileExists $socketFile

    assertFileContent $serviceFile ${builtins.toFile "expected-service" ''
      [Service]
      ExecStart=@yubikey-agent@/bin/yubikey-agent -l %t/yubikey-agent/yubikey-agent.sock
      ReadWritePaths=%t
      Type=simple

      [Unit]
      After=yubikey-agent.socket
      Description=Seamless ssh-agent for YubiKeys
      Documentation=https://github.com/FiloSottile/yubikey-agent
      RefuseManualStart=true
      Requires=yubikey-agent.socket
    ''}

    assertFileContent $socketFile ${builtins.toFile "expected-socket" ''
      [Install]
      WantedBy=sockets.target

      [Socket]
      DirectoryMode=0700
      ListenStream=%t/yubikey-agent/yubikey-agent.sock
      RuntimeDirectory=yubikey-agent
      SocketMode=0600

      [Unit]
      Description=Unix domain socket for Yubikey SSH agent
      Documentation=https://github.com/FiloSottile/yubikey-agent
    ''}
  '';
}
