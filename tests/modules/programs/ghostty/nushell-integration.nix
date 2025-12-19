{ config, pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = null; };
    enableNushellIntegration = true;
  };

  programs.nushell.enable = true;

  nmt.script =
    let
      nushellConfigDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
    in
    ''
      assertFileExists "${nushellConfigDir}/config.nu"
      assertFileRegex "${nushellConfigDir}/config.nu" \
        'if \(\$env \| get -i GHOSTTY_RESOURCES_DIR \| is-not-empty\) \{'
      assertFileRegex "${nushellConfigDir}/config.nu" \
        'source \$"\(\$env\.GHOSTTY_RESOURCES_DIR\)/shell-integration/nu/init\.nu"'
    '';
}
