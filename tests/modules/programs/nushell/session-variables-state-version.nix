{
  stateVersion,
  loadSessionVariables ? null,
}:
{ lib, ... }:
{
  home.stateVersion = stateVersion;
  programs.nushell = {
    enable = true;
  }
  // lib.optionalAttrs (loadSessionVariables != null) { inherit loadSessionVariables; };

  nmt.script =
    let
      enabled =
        if loadSessionVariables != null then
          loadSessionVariables
        else
          lib.versionAtLeast stateVersion "26.11";
      envFile = "home-files/.config/nushell/env.nu";
    in
    if enabled then
      ''
        assertFileRegex ${envFile} '^source /nix/store/[^/]*-hm-session-vars.nu$'
      ''
    else
      ''
        assertPathNotExists ${envFile}
      '';
}
