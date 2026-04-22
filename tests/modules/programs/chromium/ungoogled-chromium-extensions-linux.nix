{ pkgs, ... }:
let
  extensionId = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  extensionCrx = builtins.toFile "ungoogled-chromium-extension.crx" "dummy";
in
{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    extensions = [
      {
        id = extensionId;
        crxPath = extensionCrx;
        version = "1.0";
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/chromium/External Extensions/${extensionId}.json" \
      ${builtins.toFile "ungoogled-chromium-extension.json" (
        builtins.toJSON {
          external_crx = extensionCrx;
          external_version = "1.0";
        }
      )}
    assertPathNotExists "home-files/.config/ungoogled-chromium/External Extensions/${extensionId}.json"
  '';
}
