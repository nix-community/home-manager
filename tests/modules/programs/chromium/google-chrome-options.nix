{ config, pkgs, ... }:
let
  nativeMessagingHost = config.lib.test.mkStubPackage {
    name = "native-messaging-host";
    buildScript = ''
      mkdir -p $out/etc/chromium/native-messaging-hosts
      echo test > $out/etc/chromium/native-messaging-hosts/com.example.test.json
    '';
  };

  dictionary = config.lib.test.mkStubPackage {
    name = "chromium-dictionary";
    buildScript = ''
      echo test > "$out"
    '';
    extraAttrs = {
      passthru.dictFileName = "en-US-9-0.bdic";
    };
  };

  browserDir =
    browser:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${
        {
          google-chrome = "Google/Chrome";
          google-chrome-beta = "Google/Chrome Beta";
          google-chrome-dev = "Google/Chrome Dev";
        }
        .${browser}
      }"
    else
      ".config/${browser}";

  chromeDir = browserDir "google-chrome";
  chromeBetaDir = browserDir "google-chrome-beta";
  chromeDevDir = browserDir "google-chrome-dev";
in
{
  programs.google-chrome = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome";
    };
    dictionaries = [ dictionary ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  programs.google-chrome-beta = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-beta";
    };
    dictionaries = [ dictionary ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  programs.google-chrome-dev = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-dev";
    };
    dictionaries = [ dictionary ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  nmt.script = ''
    assertFileExists "home-files/${chromeDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeDir}/NativeMessagingHosts/com.example.test.json"

    assertFileExists "home-files/${chromeBetaDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeBetaDir}/NativeMessagingHosts/com.example.test.json"

    assertFileExists "home-files/${chromeDevDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeDevDir}/NativeMessagingHosts/com.example.test.json"
  '';
}
