{
  config,
  lib,
  pkgs,
  ...
}:

let
  launchdNixProfiles = lib.concatStringsSep " " [
    "/nix/var/nix/profiles/default"
    config.home.profileDirectory
  ];
in
{
  config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.programs.fish.enable) {
    home.activation.setFishLaunchdNixProfiles = lib.hm.dag.entryAfter [ "installPackages" ] ''
      # Fish derives vendor completions, functions, and conf.d paths from
      # NIX_PROFILES before config.fish runs, so keep launchd's inherited
      # profile list aligned with the active Home Manager profile.
      if ! run --silence /bin/launchctl setenv NIX_PROFILES ${lib.escapeShellArg launchdNixProfiles}; then
        warnEcho "Failed to update launchd NIX_PROFILES; fish vendor paths may be incomplete until the next GUI login"
      fi
    '';
  };
}
