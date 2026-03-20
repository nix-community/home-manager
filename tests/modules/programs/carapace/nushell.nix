{
  lib,
  pkgs,
  realPkgs,
  config,
  ...
}:

{
  programs = {
    carapace.enable = true;
    nushell.enable = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

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
        'source /nix/store/[^/]*-carapace-nushell-config.nu'
    '';
}
