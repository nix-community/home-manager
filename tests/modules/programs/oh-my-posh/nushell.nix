{ pkgs, ... }:

{
  programs = {
    nushell.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  test.stubs = {
    oh-my-posh = { };
    nushell = { };
  };

  nmt.script = let
    configFile = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell/config.nu"
    else
      "home-files/.config/nushell/config.nu";

    envFile = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell/env.nu"
    else
      "home-files/.config/nushell/env.nu";
  in ''
    assertFileExists "${envFile}"
    assertFileRegex \
      "${envFile}" \
      '/bin/oh-my-posh init nu --config .*--print \| save --force /.*/home-files/\.cache/oh-my-posh/init\.nu'

    assertFileExists "${configFile}"
    assertFileRegex \
      "${configFile}" \
      'source /.*/\.cache/oh-my-posh/init\.nu'
  '';
}
