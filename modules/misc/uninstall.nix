{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption types;

in {
  options.uninstall = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to set up a minimal configuration that will remove all managed
      files and packages.

      Use this with extreme care since running the generated activation script
      will remove all Home Manager state from your user environment. This
      includes removing all your historic Home Manager generations.
    '';
  };

  config = mkIf config.uninstall {
    home.packages = lib.mkForce [ ];
    home.file = lib.mkForce { };
    home.stateVersion = lib.mkForce "23.11";
    home.enableNixpkgsReleaseCheck = lib.mkForce false;
    manual.manpages.enable = lib.mkForce false;
    news.display = lib.mkForce "silent";

    home.activation.uninstall =
      lib.hm.dag.entryAfter [ "installPackages" "linkGeneration" ] ''
        nixProfileRemove home-manager-path

        if [[ -e $hmDataPath ]]; then
            run rm $VERBOSE_ARG -r "$hmDataPath"
        fi

        if [[ -e $hmStatePath ]]; then
            run rm $VERBOSE_ARG -r "$hmStatePath"
        fi

        if [[ -e $genProfilePath ]]; then
            run rm $VERBOSE_ARG "$genProfilePath"*
        fi

        if [[ -e $legacyGenGcPath ]]; then
            run rm $VERBOSE_ARG "$legacyGenGcPath"
        fi
      '';
  };
}
