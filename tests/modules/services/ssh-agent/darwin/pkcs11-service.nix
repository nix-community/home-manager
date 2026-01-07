{
  config,
  ...
}:

{
  services.ssh-agent = {
    enable = true;
    pkcs11Whitelist = [
      "/usr/lib/libpkcs11.so"
      "/usr/lib/other.so"
    ];
    package = config.lib.test.mkStubPackage { outPath = "@openssh@"; };
  };

  nmt.script = ''
    assertFileContent \
      LaunchAgents/org.nix-community.home.ssh-agent.plist \
      ${./pkcs11-service-expected.plist}
  '';
}
