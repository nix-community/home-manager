{ config, pkgs, ... }:

{
  config = {
    services.barrier.client = {
      enable = true;
      server = "testServer";
    };

    test.stubs.barrier = { };

    nmt.script = ''
      clientServiceFile=home-files/.config/systemd/user/barrierc.service

      assertFileExists $clientServiceFile
      assertFileRegex $clientServiceFile 'ExecStart=.*/bin/barrierc --enable-crypto -f testServer'
    '';
  };
}
