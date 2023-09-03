{ pkgs, ... }:

{
  programs = {
    carapace.enable = true;
    nushell.enable = true;
  };

  nmt.script = let
    configDir = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell"
    else
      "home-files/.config/nushell";
  in ''
    assertFileExists "${configDir}/env.nu"
    assertFileRegex "${configDir}/env.nu" \
      '/nix/store/.*carapace.*/bin/carapace _carapace nushell \| save -f \$"(\$carapace_cache)/init\.nu"'
    assertFileExists "${configDir}/config.nu"
    assertFileRegex "${configDir}/config.nu" \
      'source /.*/\.cache/carapace/init\.nu'
  '';
}
