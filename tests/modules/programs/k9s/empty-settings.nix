{ pkgs, lib, ... }:

{
  programs.k9s.enable = true;

  xdg.enable = lib.mkIf pkgs.stdenv.isDarwin (lib.mkForce false);

  nmt.script = let
    configDir = if !pkgs.stdenv.isDarwin then
      ".config/k9s"
    else
      "Library/Application Support/k9s";
  in ''
    assertPathNotExists home-files/${configDir}
  '';
}
