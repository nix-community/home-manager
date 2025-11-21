{
  config,
  ...
}:

{
  programs.wayprompt = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      group = {
        some-integer = 42;
        some-string = "foo:bar=37";
      };
      band = {
        sunrise = "F7CD5D";
        sunset = "fad6a5";
        white-with-alpha = "ffffff00";
      };
    };
  };

  nmt.script = ''
    local configFile=home-files/.config/wayprompt/config.ini

    assertFileExists $configFile
    assertFileContent $configFile ${./example-settings-expected.ini}
  '';
}
