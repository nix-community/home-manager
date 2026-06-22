{ config, pkgs, ... }:
let
  fakeAnkiPython = config.lib.test.mkStubPackage {
    name = "python3";
    extraAttrs = {
      isPy3 = true;
      interpreter = pkgs.writeShellScript "fake-anki-python" ''
        mkdir -p "$2"
        touch "$2/prefs21.db"
      '';
    };
  };

  fakeAnki = config.lib.test.mkStubPackage {
    name = "anki";
    extraAttrs = {
      nativeBuildInputs = [ fakeAnkiPython ];
      withAddons = _: fakeAnki;
    };
  };
in
{
  programs.anki = {
    enable = true;
    package = fakeAnki;
  };

  nmt.script =
    let
      ankiBaseDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/Anki2"
        else
          "home-files/.local/share/Anki2";
    in
    ''
      assertFileExists "${ankiBaseDir}/prefs21.db"
    '';
}
