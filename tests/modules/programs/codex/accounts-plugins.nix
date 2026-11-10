{ lib, ... }:
{
  imports = [ ./plugins.nix ];
  programs.codex.accounts.work.home = ".codex-work";
  nmt.script = lib.mkAfter ''
    assertFileContains home-files/.codex-work/config.toml '[plugins."sample-plugin@home-manager"]'
    assertFileExists home-files/.codex-work/plugins/cache/home-manager/sample-plugin/1.0.0/.codex-plugin/plugin.json
    assertFileExists home-files/.codex-work/plugins/cache/home-manager/contextual-plugin/2.0.0/.codex-plugin/plugin.json
    assertLinkExists home-files/.codex-work/plugins/cache/home-manager/-..-..-outside/1.0.0-touch-pwned-
  '';
}
