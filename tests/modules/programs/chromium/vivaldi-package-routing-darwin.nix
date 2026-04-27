{
  config,
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
in
{
  programs.chromium = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vivaldi";
    };
    dictionaries = [ dictionary ];
    extensions = [
      {
        id = extensionId;
      }
    ];
    nativeMessagingHosts = [ nativeMessagingHost ];
  };

  nmt.script = ''
    assertFileExists "home-files/Library/Application Support/Vivaldi/Dictionaries/en-US-9-0.bdic"
    assertFileExists "home-files/Library/Application Support/Vivaldi/NativeMessagingHosts/com.example.test.json"
    assertFileContent \
      "home-files/Library/Application Support/Vivaldi/External Extensions/${extensionId}.json" \
      ${builtins.toFile "chromium-vivaldi-extension.json" (
        builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        }
      )}
    assertPathNotExists "home-files/Library/Application Support/vivaldi/External Extensions/${extensionId}.json"
  '';
}
