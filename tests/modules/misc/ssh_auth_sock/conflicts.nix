{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
  services.ssh-agent.enable = true;

  test.asserts.assertions.expected = [
    ''
      Out of the SSH agents

      - ssh-agent or ssh-tpm-agent (these two can coexist),
      - gpg-agent with SSH support enabled, and
      - yubikey-agent,

      at most one of them may be enabled (with the exception of ssh-agent and
      ssh-tpm-agent).
    ''
  ];
}
