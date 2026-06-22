{
  config,
  ...
}:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
in
{
  programs.chromium = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-dev";
    };
    extensions = [
      {
        id = extensionId;
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
      "home-files/Library/Application Support/Google/Chrome Dev/External Extensions/${extensionId}.json" \
      ${builtins.toFile "chromium-google-chrome-dev-extension.json" (
        builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        }
      )}
    assertPathNotExists "home-files/Library/Application Support/Chromium/External Extensions/${extensionId}.json"
  '';
}
