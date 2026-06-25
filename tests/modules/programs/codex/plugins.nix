{ config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
    version = "0.94.0";
  };
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    plugins = [
      ./sample-plugin
      ./unsafe-plugin
    ];
    marketplaces.team = ./sample-marketplace;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContains home-files/.codex/config.toml '[features]'
    assertFileContains home-files/.codex/config.toml 'plugins = true'
    assertFileContains home-files/.codex/config.toml '[marketplaces.team]'
    assertFileContains home-files/.codex/config.toml 'source_type = "local"'
    assertFileContains home-files/.codex/config.toml 'source = "${./sample-marketplace}"'
    assertFileContains home-files/.codex/config.toml '[plugins."sample-plugin@home-manager"]'
    assertFileContains home-files/.codex/config.toml '[plugins."../../../outside@home-manager"]'
    assertFileContains home-files/.codex/config.toml 'enabled = true'

    assertFileExists home-files/.agents/plugins/marketplace.json
    assertFileContains home-files/.agents/plugins/marketplace.json '"name": "home-manager"'
    assertFileContains home-files/.agents/plugins/marketplace.json '"name": "sample-plugin"'
    assertFileContains home-files/.agents/plugins/marketplace.json '"path": "./.codex/plugins/cache/home-manager/sample-plugin/1.0.0"'
    assertFileContains home-files/.agents/plugins/marketplace.json '"name": "../../../outside"'
    assertFileContains home-files/.agents/plugins/marketplace.json '"path": "./.codex/plugins/cache/home-manager/-..-..-outside/1.0.0-touch-pwned-"'

    assertLinkExists home-files/.codex/plugins/cache/home-manager/sample-plugin/1.0.0
    assertFileExists home-files/.codex/plugins/cache/home-manager/sample-plugin/1.0.0/.codex-plugin/plugin.json
    assertFileContent \
      home-files/.codex/plugins/cache/home-manager/sample-plugin/1.0.0/.codex-plugin/plugin.json \
      ${./sample-plugin/.codex-plugin/plugin.json}
    assertFileExists home-files/.codex/plugins/cache/home-manager/sample-plugin/1.0.0/skills/sample/SKILL.md
    assertLinkExists home-files/.codex/plugins/cache/home-manager/-..-..-outside/1.0.0-touch-pwned-
    assertFileExists home-files/.codex/plugins/cache/home-manager/-..-..-outside/1.0.0-touch-pwned-/.codex-plugin/plugin.json
    assertPathNotExists home-files/.codex/plugins/outside
  '';
}
