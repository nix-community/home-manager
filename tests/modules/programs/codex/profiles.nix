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
    };
    profiles = {
      deep-review = {
        approval_policy = "on-request";
        model = "gpt-5.5";
        model_reasoning_effort = "xhigh";
        sandbox_mode = "workspace-write";
      };
      ci = {
        approval_policy = "never";
        sandbox_mode = "workspace-write";
      };
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./profiles-config.toml}
    assertFileExists home-files/.codex/deep-review.config.toml
    assertFileContent home-files/.codex/deep-review.config.toml \
      ${./profiles-deep-review.toml}
    assertFileExists home-files/.codex/ci.config.toml
    assertFileContent home-files/.codex/ci.config.toml \
      ${./profiles-ci.toml}
  '';
}
