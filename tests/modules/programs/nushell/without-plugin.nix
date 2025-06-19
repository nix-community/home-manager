{
  pkgs,
  realPkgs,
  config,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = realPkgs.nushell;
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
      assertPathNotExists "${configDir}/plugin.msgpackz"
    '';
}
