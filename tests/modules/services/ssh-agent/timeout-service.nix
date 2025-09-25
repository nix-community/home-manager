{
  services.ssh-agent = {
    enable = true;
    defaultTimeout = 1337;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/ssh-agent.service \
      ${./timeout-service-expected.service}
  '';
}
