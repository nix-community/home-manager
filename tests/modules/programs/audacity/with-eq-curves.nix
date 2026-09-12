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
    eqCurves = {
      equalizationeffect.curve = [
        {
          "@name" = "My Curve";
          point = [
            {
              "@f" = "20.0";
              "@d" = "0.0";
            }
            {
              "@f" = "1000.0";
              "@d" = "3.0";
            }
          ];
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists "${configDir}/EQCurves.xml"
  '';
}
