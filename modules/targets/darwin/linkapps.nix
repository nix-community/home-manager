{ config, lib, pkgs, ... }:

{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    # Install MacOS applications to the user environment.
    home.file."Applications/Home Manager Apps".source = let
      apps = (pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      }).overrideAttrs
        (old: { __noChroot = config.home.buildEnvWithNoChroot; });
    in "${apps}/Applications";
  };
}
