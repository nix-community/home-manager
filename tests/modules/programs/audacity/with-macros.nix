{ config, pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/audacity/Macros"
    else
      "home-files/.local/share/audacity/Macros";
in
{
  programs.audacity = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "3.7.7"; };
    macros = {
      normalize-and-export = [
        { command = "SelectAll"; }
        {
          command = "Normalize";
          params = {
            ApplyGain = "0";
            PeakLevel = "-1";
          };
        }
        {
          command = "Export2";
          params = {
            Filename = "output";
            Format = "FLAC";
          };
        }
      ];
    };
  };

  nmt.script = ''
    macroFile="${configDir}/normalize-and-export.txt"
    assertFileExists "$macroFile"
    assertFileContent "$macroFile" ${builtins.toFile "expected" ''
      SelectAll:
      Normalize:ApplyGain="0" PeakLevel="-1"
      Export2:Filename="output" Format="FLAC"
    ''}
  '';
}
