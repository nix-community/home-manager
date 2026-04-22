{ config, pkgs, ... }:
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
    extensions = [
      {
        id = extensionId;
        updateUrl = "https://example.com/update.xml";
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

      assertPathNotExists "home-files/${chromeDir}/External Extensions/${extensionId}.json"
      assertPathNotExists "home-files/${chromiumDir}/External Extensions/${extensionId}.json"
    '';
}
