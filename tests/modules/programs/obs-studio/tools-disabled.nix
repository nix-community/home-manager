{
  lib,
  pkgs,
  ...
}:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';
in
{
  programs.obs-studio = {
    enable = true;
    package = obsPackage;
    tools.enable = false;
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    assertPathNotExists home-path/bin/hermesix
    assertPathNotExists home-path/bin/hm-managed-config
    assertPathNotExists home-path/bin/obs-studio-sync
    assertPathNotExists home-path/bin/obs-studio-export-to-nix
  '';
}
