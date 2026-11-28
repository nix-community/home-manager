{ pkgs, config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
    buildScript = ''
      mkdir -p "$out/bin"
      touch "$out/bin/codex"
      chmod +x "$out/bin/codex"
    '';
  };
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    extraPackages = with pkgs; [
      python3
      nodejs
    ];
  };

  test.stubs = {
    python3.name = "python3";
    nodejs.name = "nodejs";
  };

  nmt = {
    description = "Check that extraPackages are available to Codex";
    script = ''
      codexWrapper="$TESTED/home-path/bin/codex"
      assertFileExists "$codexWrapper"
      assertFileRegex "$codexWrapper" "python3"
      assertFileRegex "$codexWrapper" "nodejs"
      assertPathNotExists "$TESTED/home-path/bin/python3"
      assertPathNotExists "$TESTED/home-path/bin/node"
    '';
  };
}
