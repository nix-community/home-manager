{ config, lib, pkgs, ... }:

{
  # Disabled for now due to conflicting behavior with nix-darwin. See
  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-687286866
  config = lib.mkIf (false && pkgs.stdenv.hostPlatform.isDarwin) {
    # Install MacOS applications to the user environment.
    home.file."Applications/Home Manager Apps".source = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in "${apps}/Applications";
  };
}
