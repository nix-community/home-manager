{
  programs.gpg = {
    enable = true;

    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "32769";
      application-priority = "openpgp p15 sc-hsm nks geldkarte dinsig";
    };

    dirmngrSettings = {
      use-tor = true;
      keyserver = "ldaps://ldap.example.com";
    };

    gpgsmSettings = {
      cipher-algo = "AES256";
      with-md5-fingerprint = true;
      validation-model = "steed";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.gnupg/scdaemon.conf
    assertFileExists home-files/.gnupg/dirmngr.conf
    assertFileExists home-files/.gnupg/gpgsm.conf

    assertFileContent home-files/.gnupg/scdaemon.conf ${./other-scdaemon.conf}
    assertFileContent home-files/.gnupg/dirmngr.conf ${./other-dirmngr.conf}
    assertFileContent home-files/.gnupg/gpgsm.conf ${./other-gpgsm.conf}
  '';
}
