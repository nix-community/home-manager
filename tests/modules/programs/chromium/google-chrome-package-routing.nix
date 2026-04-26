{
  config,
  lib,
  pkgs,
  ...
}:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
in
{
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
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
    extensions = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      {
        id = extensionId;
      }
    ];
  };

  nmt.script =
    let
      chromeDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Google/Chrome"
        else
          ".config/google-chrome";

      chromiumDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Chromium"
        else
          ".config/chromium";
    in
    ''
      assertFileExists "home-files/${chromeDir}/Dictionaries/en-US-9-0.bdic"
      assertPathNotExists "home-files/${chromiumDir}/Dictionaries/en-US-9-0.bdic"

      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        assertFileContent \
          "home-files/${chromeDir}/External Extensions/${extensionId}.json" \
          ${builtins.toFile "chromium-google-chrome-extension.json" (
            builtins.toJSON {
              external_update_url = "https://clients2.google.com/service/update2/crx";
            }
          )}
      ''}
      assertPathNotExists "home-files/${chromiumDir}/External Extensions/${extensionId}.json"
    '';
}
