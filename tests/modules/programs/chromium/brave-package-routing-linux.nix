{ config, ... }:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
in
{
  programs.chromium = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "brave";
    };
    extensions = [
      {
        id = extensionId;
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/BraveSoftware/Brave-Browser/External Extensions/${extensionId}.json" \
      ${builtins.toFile "chromium-brave-extension.json" (
        builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        }
      )}
    assertPathNotExists "home-files/.config/chromium/External Extensions/${extensionId}.json"
  '';
}
