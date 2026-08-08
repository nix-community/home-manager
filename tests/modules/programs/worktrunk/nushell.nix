{ pkgs, config, ... }:
{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableNushellIntegration = true;
    nushell.enable = true;
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
    in
    ''
      assertFileExists "${configDir}/config.nu"
      assertFileRegex "${configDir}/config.nu" \
        'source /nix/store/[^/]*-worktrunk-nushell-config.nu'
    '';
}
