{
  services.ssh-agent = {
    enable = true;
    defaultMaximumIdentityLifetime = 1337;
  };

  nmt.script = ''
    assertFileContent \
      $(normalizeStorePaths home-files/.config/systemd/user/ssh-agent.service) \
      ${./timeout-service-expected.service}
  '';
}
