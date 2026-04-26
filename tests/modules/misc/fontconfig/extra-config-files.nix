{ lib, ... }:

let
  fcConfD = "home-files/.config/fontconfig/conf.d";
  sampleText = "hello world";
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
      settings.settings.a = [
        {
          "@attr" = "value";
          b = 1;
        }
        { c = "string"; }
      ];
      text.text = sampleText;
      source.source = sampleSource;
    };
  };

  nmt.script = ''
    assertDirectoryExists ${fcConfD}

    assertPathNotExists ${fcConfD}/90-hm-disabled.conf

    assertFileExists ${fcConfD}/90-hm-custom_label.conf

    assertFileExists ${fcConfD}/37-hm-priority.conf

    assertFileExists ${fcConfD}/target

    assertFileExists  ${fcConfD}/90-hm-settings.conf
    assertFileContent ${fcConfD}/90-hm-settings.conf ${builtins.toFile "sample-settings-config" ''
      <?xml version="1.0" encoding="utf-8"?>
      <fontconfig>
        <a attr="value">
          <b>1</b>
        </a>
        <a>
          <c>string</c>
        </a>
      </fontconfig>
    ''}

    assertFileExists  ${fcConfD}/90-hm-text.conf
    assertFileContent ${fcConfD}/90-hm-text.conf \
      ${builtins.toFile "sample-text-config" sampleText}

    assertFileExists  ${fcConfD}/90-hm-source.conf
    assertFileContent ${fcConfD}/90-hm-source.conf ${sampleSource}
  '';
}
