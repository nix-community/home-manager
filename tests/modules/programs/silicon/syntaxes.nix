{ pkgs, ... }:

let syntaxName = "gleam";
in {
  programs.silicon = {
    enable = true;
    syntaxes = {
      ${syntaxName} = {
        src = pkgs.fetchFromGitHub {
          owner = "molnarmark";
          repo = "sublime-gleam";
          rev = "2e761cdb1a87539d827987f997a20a35efd68aa9";
          hash = "sha256-Zj2DKTcO1t9g18qsNKtpHKElbRSc9nBRE2QBzRn9+qs=";
        };
        file = "syntax/gleam.sublime-syntax";
      };
    };
  };

  test.stubs.silicon = { };

  nmt.script = let
    syntaxFile =
      "home-files/.config/silicon/syntaxes/${syntaxName}.sublime-syntax";
    cacheFile = "home-files/.cache/silicon/syntaxes.bin";
  in ''
    assertFileExists "${syntaxFile}"
    assertFileExists "${cacheFile}"
  '';
}
