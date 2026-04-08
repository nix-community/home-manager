{ lib, pkgs, ... }:

let
  workspaceDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/DBeaverData/workspace6"
    else
      "home-files/.local/share/DBeaverData/workspace6";
in
{
  programs.dbeaver.enable = true;

  nmt.script = ''
    assertPathNotExists \
      ${workspaceDir}/General/.dbeaver/data-sources.json
    assertPathNotExists \
      ${workspaceDir}/.metadata
  '';
}
