{ config, lib, ... }:

{
  sshAuthSock = {
    enable = true;
    initialization = {
      bash = "echo bash/zsh";
      fish = "echo fish";
      nushell = "echo nushell";
    };
    systemd.socketProviderUnit = "foo.socket";
  };

  nmt.script = lib.optionalString config.systemd.user.enable ''
    serviceFile=home-files/.config/systemd/user/set-SSH_AUTH_SOCK.service

    assertFileExists $serviceFile
    assertFileContains $serviceFile 'WantedBy=default.target'
    assertFileNotRegex $serviceFile 'Before=foo\.socket'
    assertFileNotRegex $serviceFile 'WantedBy=foo\.socket'
  '';
}
