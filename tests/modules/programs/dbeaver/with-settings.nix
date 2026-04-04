{ lib, pkgs, ... }:

let
  workspaceDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/DBeaverData/workspace6"
    else
      "home-files/.local/share/DBeaverData/workspace6";
in
{
  programs.dbeaver = {
    enable = true;
    settings = {
      "org.jkiss.dbeaver.core" = {
        "ui.showSystemObjects" = "false";
        "ui.showUtilityObjects" = "false";
      };
    };
  };

  nmt.script = ''
    prefsFile=${workspaceDir}/.metadata/.plugins/org.eclipse.core.runtime/.settings/org.jkiss.dbeaver.core.prefs
    assertFileExists $prefsFile
    assertFileContent $prefsFile ${builtins.toFile "expected" ''
      eclipse.preferences.version=1
      ui.showSystemObjects=false
      ui.showUtilityObjects=false
    ''}
  '';
}
