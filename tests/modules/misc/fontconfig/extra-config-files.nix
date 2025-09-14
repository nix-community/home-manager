let
  sampleTextContent = "hello world";
  fcConfD = "home-files/.config/fontconfig/conf.d";
in
{
  fonts.fontconfig = {
    enable = true;
    configFile = {
      text-label-test = {
        enable = true;
        label = "sample-text-config";
        text = sampleTextContent;
        priority = 55;
      };
      source-nolabel-test = {
        enable = true;
        source = ./sample-extra-config.conf;
      };
    };
  };

  nmt.script = ''
    assertDirectoryExists ${fcConfD}

    assertFileExists  ${fcConfD}/55-hm-sample-text-config.conf
    assertFileContent ${fcConfD}/55-hm-sample-text-config.conf \
      ${builtins.toFile "sample-text-config" sampleTextContent}

    assertFileExists  ${fcConfD}/90-hm-source-nolabel-test.conf
    assertFileContent ${fcConfD}/90-hm-source-nolabel-test.conf \
      ${./sample-extra-config.conf}
  '';
}
