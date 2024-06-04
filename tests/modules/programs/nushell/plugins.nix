{ pkgs, config, ... }:

{
  programs.nushell = {
    enable = true;
    plugins =
      builtins.attrValues { inherit (pkgs.nushellPlugins) formats gstat; };
  };

  test.stubs."nushellPlugins.formats" = { };

  nmt.script = let
    configDir = if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "home-files/Library/Application Support/nushell"
    else
      "home-files/.config/nushell";
    pluginFile = "${configDir}/plugin.msgpackz";

  in ''
    assertFileExists "${pluginFile}"
  '';
}
