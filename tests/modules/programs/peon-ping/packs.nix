{ config, ... }:
{
  programs.peon-ping = {
    enable = true;
    packs = [
      "peon"
      "glados"
    ];
    ogPacksSource = config.lib.test.mkStubPackage {
      name = "test-og-packs";
      buildScript = ''
        mkdir -p $out/peon/sounds $out/glados/sounds
        echo '{}' > $out/peon/openpeon.json
        echo '{}' > $out/glados/openpeon.json
      '';
    };
  };

  test.stubs.peon-ping = { };

  nmt.script = ''
    assertDirectoryExists home-files/.claude/hooks/peon-ping/packs/peon
    assertDirectoryExists home-files/.claude/hooks/peon-ping/packs/glados
  '';
}
