{
  programs.firefoxpwa = {
    enable = true;
    package = null;
    profiles."0123456789ABCDEFGHJKMNPQRS".sites."ZYXWVTSRQPNMKJHGFEDCBA9876" = {
      name = "MDN Web Docs";
      url = "https://developer.mozilla.org/";
      manifestUrl = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
    };
  };

  nmt.script = ''
    configFile=home-files/.local/share/firefoxpwa/config.json
    assertFileExists $configFile
    assertFileContent $configFile ${./config-expected.json}
  '';
}
