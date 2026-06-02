{ lib, ... }:

let
  fcConfD = "home-files/.config/fontconfig/conf.d";
  sampleText = "hello world";
  sampleTextFile = builtins.toFile "sample-text-config" sampleText;
  sampleSource = builtins.toFile "fontconfig-source" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      ...
    </fontconfig>
  '';
in
{
  home.stateVersion = lib.trivial.release;

  fonts.fontconfig = {
    enable = true;
    configFile = {
      disabled = {
        enable = false;
        text = "";
      };
      label = {
        label = "custom_label";
        text = "";
      };
      priority = {
        priority = 37;
        text = "";
      };
      target = {
        target = "target";
        text = "";
      };
      text.text = sampleText;
      source.source = sampleSource;

      # Check that priorities are propagated
      text-overrides-source = {
        text = lib.mkForce sampleText;
        source = sampleSource;
      };
      source-overrides-text = {
        text = sampleText;
        source = lib.mkForce sampleSource;
      };
    };
  };

  nmt.script = ''
    assertDirectoryExists ${fcConfD}

    assertPathNotExists ${fcConfD}/90-hm-disabled.conf

    assertFileExists ${fcConfD}/90-hm-custom_label.conf

    assertFileExists ${fcConfD}/37-hm-priority.conf

    assertFileExists ${fcConfD}/target

    assertFileExists  ${fcConfD}/90-hm-text.conf
    assertFileContent ${fcConfD}/90-hm-text.conf ${sampleTextFile}

    assertFileExists  ${fcConfD}/90-hm-source.conf
    assertFileContent ${fcConfD}/90-hm-source.conf ${sampleSource}

    assertFileExists  ${fcConfD}/90-hm-text-overrides-source.conf
    assertFileContent ${fcConfD}/90-hm-text-overrides-source.conf ${sampleTextFile}

    assertFileExists  ${fcConfD}/90-hm-source-overrides-text.conf
    assertFileContent ${fcConfD}/90-hm-source-overrides-text.conf ${sampleSource}
  '';
}
