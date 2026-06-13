{ config, ... }: {
  home.file.testfile.text = "not special";
  specialisation = { test.default = true; };

  nmt.script = ''
    assertFileExists activate
    assertFileContains activate \
      "${config.specialisation.test.configuration.home.activationPackage}/activate"
  '';
}
