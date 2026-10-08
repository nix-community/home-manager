{ pkgs, lib, ... }:

{
  programs.superfile.enable = true;

  xdg.enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin false;

  nmt.script =
    let
      configDir =
        if !pkgs.stdenv.hostPlatform.isDarwin then
          ".config/superfile"
        else
          "Library/Application Support/superfile";
    in
    ''
      assertPathNotExists home-files/${configDir}
    '';
}
