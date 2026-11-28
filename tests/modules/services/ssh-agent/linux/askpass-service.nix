{
  services.ssh-agent = {
    enable = true;
    askpass = "/dev/null";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/ssh-agent.service
    assertFileContains "$serviceFile" "Environment=SSH_ASKPASS=/nix/store/"
    assertFileContains "$serviceFile" "ssh-askpass-wrapper"
    assertFileContains "$serviceFile" "Environment=SSH_ASKPASS_REQUIRE=force"
  '';
}
