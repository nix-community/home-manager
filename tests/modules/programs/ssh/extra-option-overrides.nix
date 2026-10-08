{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraOptionOverrides = {
      ForwardAgent = false;
      GlobalKnownHostsFile = [
        "/etc/ssh/ssh_known_hosts"
        "~/.ssh/global_known_hosts"
      ];
    };
    settings.space-list = {
      CanonicalDomains = [
        "example.org"
        "corp.example"
      ];
      ChannelTimeout = [
        "session=5m"
        "direct-tcpip=30s"
      ];
      GlobalKnownHostsFile = [
        "~/.ssh/known_hosts"
        "~/.ssh/known_hosts2"
      ];
      UserKnownHostsFile = [
        "~/.ssh/user_known_hosts"
        "~/.ssh/user_known_hosts2"
      ];
      PermitRemoteOpen = [
        "localhost:8080"
        "example.org:443"
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.ssh/config
    assertFileContent \
      home-files/.ssh/config \
      ${./extra-option-overrides-expected.conf}
  '';
}
