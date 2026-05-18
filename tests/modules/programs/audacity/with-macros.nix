{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/audacity"
    else
      "home-files/.config/audacity";
in
{
  programs.audacity = {
    enable = true;
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
    macroFile="${configDir}/macros/normalize-and-export.txt"
    assertFileExists "$macroFile"
    assertFileContent "$macroFile" ${builtins.toFile "expected" ''
      SelectAll
      Normalize	ApplyGain="0" PeakLevel="-1"
      Export2	Filename="output" Format="FLAC"
    ''}
  '';
}
