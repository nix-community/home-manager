{
  services.ssh-agent = {
    enable = true;
    pkcs11Whitelist = [
      "/nix/store/*/lib"
      "/usr/lib/libpkcs11.so"
      "/usr/lib/other.so"
    ];
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/ssh-agent.service \
      ${./pkcs11-service-expected.service}
  '';
}
