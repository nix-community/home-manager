{
  pkgs,
  ...
}:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/numbat"
    else
      ".config/numbat";
in
{
  programs.numbat.enable = true;

  nmt.script = ''
    assertPathNotExists 'home-files/${configDir}/config.toml'
  '';
}
