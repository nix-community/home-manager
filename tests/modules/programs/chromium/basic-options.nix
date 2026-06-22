{ config, pkgs, ... }:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
in
{
  programs.chromium = {
    enable = true;
    dictionaries = [
      (config.lib.test.mkStubPackage {
        name = "chromium-dictionary";
        buildScript = ''
          echo test > "$out"
        '';
        extraAttrs = {
          passthru.dictFileName = "en-US-9-0.bdic";
        };
      })
    ];
    nativeMessagingHosts = [
      (config.lib.test.mkStubPackage {
        name = "native-messaging-host";
        buildScript = ''
          mkdir -p $out/etc/chromium/native-messaging-hosts
          echo test > $out/etc/chromium/native-messaging-hosts/com.example.test.json
        '';
      })
    ];
    extensions = [
      {
        id = extensionId;
        updateUrl = "https://example.com/update.xml";
      }
    ];
  };

  nmt.script =
    let
      browserDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Chromium"
        else
          ".config/chromium";
    in
    ''
      assertFileExists "home-files/${browserDir}/Dictionaries/en-US-9-0.bdic"
      assertFileExists "home-files/${browserDir}/NativeMessagingHosts/com.example.test.json"
      assertFileContent \
        "home-files/${browserDir}/External Extensions/${extensionId}.json" \
        ${builtins.toFile "chromium-extension.json" (
          builtins.toJSON {
            external_update_url = "https://example.com/update.xml";
          }
        )}
    '';
}
