{
  config,
  lib,
  pkgs,
  ...
}:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
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
    extensions = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      {
        id = extensionId;
      }
    ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  programs.google-chrome-beta = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-beta";
    };
    dictionaries = [ dictionary ];
    extensions = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      {
        id = extensionId;
      }
    ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  programs.google-chrome-dev = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-dev";
    };
    dictionaries = [ dictionary ];
    extensions = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      {
        id = extensionId;
      }
    ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  nmt.script = ''
    assertFileExists "home-files/${chromeDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeDir}/NativeMessagingHosts/com.example.test.json"

    assertFileExists "home-files/${chromeBetaDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeBetaDir}/NativeMessagingHosts/com.example.test.json"

    assertFileExists "home-files/${chromeDevDir}/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/${chromeDevDir}/NativeMessagingHosts/com.example.test.json"

    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      assertFileContent \
        "home-files/${chromeDir}/External Extensions/${extensionId}.json" \
        ${builtins.toFile "google-chrome-extension.json" (
          builtins.toJSON {
            external_update_url = "https://clients2.google.com/service/update2/crx";
          }
        )}
      assertFileContent \
        "home-files/${chromeBetaDir}/External Extensions/${extensionId}.json" \
        ${builtins.toFile "google-chrome-beta-extension.json" (
          builtins.toJSON {
            external_update_url = "https://clients2.google.com/service/update2/crx";
          }
        )}
      assertFileContent \
        "home-files/${chromeDevDir}/External Extensions/${extensionId}.json" \
        ${builtins.toFile "google-chrome-dev-extension.json" (
          builtins.toJSON {
            external_update_url = "https://clients2.google.com/service/update2/crx";
          }
        )}
    ''}
  '';
}
