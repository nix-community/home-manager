{
  services.barrier.client = {
    enable = true;
    server = "testServer";
  };

  nmt.script = ''
    clientServiceFile=home-files/.config/systemd/user/barrierc.service

    assertFileExists $clientServiceFile
    assertFileRegex $clientServiceFile 'ExecStart=.*/bin/barrierc -f testServer'
  '';
}
