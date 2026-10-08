{ pkgs, ... }:
let
  codexPackage = pkgs.runCommand "codex-0.133.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/codex
    chmod +x $out/bin/codex
  '';
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    settings = {
      model = "gpt-5";
      profile = "deep-review";
      profiles.deep-review = {
        approval_policy = "on-request";
        sandbox_mode = "workspace-write";
      };
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./profiles-legacy-old-version.toml}
    assertPathNotExists home-files/.codex/deep-review.config.toml
  '';
}
