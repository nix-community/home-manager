{ lib, ... }:

let
  fcConfD = "home-files/.config/fontconfig/conf.d";
  sampleSettings = {
    a = [
      {
        "@attr" = "value";
        b = 1;
      }
      { c = "string"; }
    ];
  };
  sampleSettingsFile = builtins.toFile "sample-settings-config" ''
    <?xml version="1.0" encoding="utf-8"?>
    <fontconfig>
      <a attr="value">
        <b>1</b>
      </a>
      <a>
        <c>string</c>
      </a>
    </fontconfig>
  '';
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
      settings.settings = sampleSettings;
      text.text = sampleText;
      source.source = sampleSource;

      # Check that priorities are propagated
      settings-override-text = {
        settings = lib.mkForce sampleSettings;
        text = sampleText;
      };
      settings-override-source = {
        settings = lib.mkForce sampleSettings;
        source = sampleSource;
      };
      text-overrides-source = {
        text = lib.mkForce sampleText;
        source = sampleSource;
      };
      text-overrides-settings = {
        settings = sampleSettings;
        text = lib.mkForce sampleText;
      };
      source-overrides-settings = {
        settings = sampleSettings;
        source = lib.mkForce sampleSource;
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

    assertFileExists  ${fcConfD}/90-hm-settings.conf
    assertFileContent ${fcConfD}/90-hm-settings.conf ${sampleSettingsFile}

    assertFileExists  ${fcConfD}/90-hm-text.conf
    assertFileContent ${fcConfD}/90-hm-text.conf ${sampleTextFile}

    assertFileExists  ${fcConfD}/90-hm-source.conf
    assertFileContent ${fcConfD}/90-hm-source.conf ${sampleSource}

    assertFileExists  ${fcConfD}/90-hm-settings-override-text.conf
    assertFileContent ${fcConfD}/90-hm-settings-override-text.conf ${sampleSettingsFile}

    assertFileExists  ${fcConfD}/90-hm-settings-override-source.conf
    assertFileContent ${fcConfD}/90-hm-settings-override-source.conf ${sampleSettingsFile}

    assertFileExists  ${fcConfD}/90-hm-text-overrides-source.conf
    assertFileContent ${fcConfD}/90-hm-text-overrides-source.conf ${sampleTextFile}

    assertFileExists  ${fcConfD}/90-hm-text-overrides-settings.conf
    assertFileContent ${fcConfD}/90-hm-text-overrides-settings.conf ${sampleTextFile}

    assertFileExists  ${fcConfD}/90-hm-source-overrides-settings.conf
    assertFileContent ${fcConfD}/90-hm-source-overrides-settings.conf ${sampleSource}

    assertFileExists  ${fcConfD}/90-hm-source-overrides-text.conf
    assertFileContent ${fcConfD}/90-hm-source-overrides-text.conf ${sampleSource}
  '';
}
