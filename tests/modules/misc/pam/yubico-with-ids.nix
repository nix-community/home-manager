{
  config = {
    pam.yubico.authorizedYubiKeys.ids = [ "abcdefghijkl" "012345678912" ];

    nmt.script = ''
      assertFileExists home-files/.yubico/authorized_yubikeys
      assertFileContent \
        home-files/.yubico/authorized_yubikeys \
        ${./yubico-with-ids-expected.txt}
    '';
  };
}
