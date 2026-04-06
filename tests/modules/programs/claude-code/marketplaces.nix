{ config, ... }:

{
  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    enable = true;

    marketplaces = {
      test-market = ./test-marketplace;
      test-duplicate = ./test-marketplace;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/plugins/known_marketplaces.json
    assertLinkExists home-files/.claude/plugins/known_marketplaces.json
    normalizedFile=$(normalizeStorePaths home-files/.claude/plugins/known_marketplaces.json)
    assertFileContent "$normalizedFile" ${./expected-known-marketplaces.json}
    normalizedFile=$(normalizeStorePaths home-files/.claude/settings.json)
    assertFileContent "$normalizedFile" ${./expected-settings-marketplaces.json}
  '';
}
