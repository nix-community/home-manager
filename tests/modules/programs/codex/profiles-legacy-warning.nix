{ pkgs, ... }:
let
  codexPackage = pkgs.runCommand "codex-0.134.0" { } ''
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

  test.asserts.warnings.expected = [
    ''
      `programs.codex.settings.profile` and `programs.codex.settings.profiles`
      are no longer supported by Codex 0.134.0 and later. Home Manager
      now writes entries from `programs.codex.settings.profiles` to
      `CODEX_HOME/<name>.config.toml`. Move them to
      `programs.codex.profiles` and remove `programs.codex.settings.profile`.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./profiles-legacy-warning.toml}
    assertFileExists home-files/.codex/deep-review.config.toml
    assertFileContent home-files/.codex/deep-review.config.toml \
      ${./profiles-legacy-warning-deep-review.toml}
  '';
}
