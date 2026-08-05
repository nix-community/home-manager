{ config, realPkgs, ... }:

let
  src = realPkgs.runCommand "codex-ifd-derived-sources" { } ''
    mkdir -p \
      "$out/hooks" \
      "$out/marketplace" \
      "$out/plugin/.codex-plugin" \
      "$out/rules"

    echo '{"hooks": {}}' > "$out/hooks/hooks.json"
    echo '#!/bin/sh' > "$out/hooks/test.sh"
    echo '{"name":"marketplace"}' > "$out/marketplace/marketplace.json"
    echo '{"name":"plugin","version":"0.0.0"}' > "$out/plugin/.codex-plugin/plugin.json"
    echo 'prefix_rule(pattern = ["nix"], decision = "allow")' > "$out/rules/derived.rules"
  '';
in
{
  programs.codex = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "codex";
      version = "0.94.0";
    };
    hooks = "${src}/hooks";
    marketplaces.local = "${src}/marketplace";
    plugins = [ "${src}/plugin" ];
    rules.derived = "${src}/rules/derived.rules";
  };

  nmt.script = ''
    assertFileContent home-files/.codex/hooks.json \
      "${src}/hooks/hooks.json"
    assertFileContent home-files/.codex/hooks/test.sh \
      "${src}/hooks/test.sh"
    assertFileContent home-files/.codex/rules/derived.rules \
      "${src}/rules/derived.rules"

    assertLinkExists home-files/.codex/plugins/cache/home-manager/plugin/0.0.0
    assertFileContent \
      home-files/.codex/plugins/cache/home-manager/plugin/0.0.0/.codex-plugin/plugin.json \
      "${src}/plugin/.codex-plugin/plugin.json"

    assertFileContains home-files/.codex/config.toml '[marketplaces.local]'
    assertFileContains home-files/.codex/config.toml 'source_type = "local"'
    assertFileContains home-files/.codex/config.toml '[plugins."plugin@home-manager"]'
  '';
}
