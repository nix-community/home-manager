{
  lib,
  pkgs,
  realPkgs,
  config,
  ...
}:

{
  programs = {
    nushell.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/config.nu"
        else
          "home-files/.config/nushell/config.nu";
    in
    ''
      assertFileExists "${configFile}"
      assertFileRegex \
        "${configFile}" \
        'source /nix/store/[^/]*-oh-my-posh-nushell-config.nu'
    '';
}
