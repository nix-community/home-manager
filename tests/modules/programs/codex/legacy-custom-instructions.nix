{
  lib,
  options,
  pkgs,
  ...
}:
let
  codexPackage = pkgs.runCommand "codex-0.2.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/codex
    chmod +x $out/bin/codex
  '';
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    custom-instructions = ./AGENTS.md;
  };

  test.asserts.warnings.expected = [
    "The option `programs.codex.custom-instructions' defined in ${lib.showFiles options.programs.codex.custom-instructions.files} has been renamed to `programs.codex.context'."
  ];

  nmt.script = ''
    assertFileExists home-files/.codex/AGENTS.md
    assertFileContent home-files/.codex/AGENTS.md \
      ${./AGENTS.md}
  '';
}
