# Adapted from Nixpkgs.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.ihaskell;
  ihaskellSrc = pkgs.fetchFromGitHub {
    owner = "gibiansky";
    repo = "IHaskell";
    rev = "c2cb8e6789c3f2485ba9e1e0436177b700edb227";
    sha256 = "0h5hpdfa3daabf1ijl7y5qnpy60yrf7h0ws2n3v5przfmgr8phv5";
  };
  ihaskellResult = (import (ihaskellSrc + /release.nix) {
    compiler = "ghc864";
    packages = self: cfg.extraPackages self;
  });

in

{
  meta.maintainers = [ maintainers.rycee ];

  options.services.ihaskell = {
    enable = mkOption {
      default = false;
      description = "Autostart an IHaskell notebook service.";
    };

    notebooksPath = mkOption {
      default = "$HOME/ihaskell";
      example = literalExample ''
        $HOME/projects/ihaskell-notebooks
      '';
      description = ''
        Directory where iHaskell will store notebooks
      '';
    };

    extraPackages = mkOption {
      default = self: [];
      example = literalExample ''
        haskellPackages: [
          haskellPackages.wreq
          haskellPackages.lens
        ]
      '';
      description = ''
        Extra packages available to ghc when running ihaskell. The
        value must be a function which receives the attrset defined
        in <varname>haskellPackages</varname> as the sole argument.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.ihaskell = {
      Unit = {
        Description = "iHaskell notebook instance";
        After = [ "network.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.runtimeShell} -c \"mkdir -p ${cfg.notebooksPath}; cd ${cfg.notebooksPath}; ${ihaskellResult}/bin/ihaskell-notebook\"";
        RestartSec = 3;
        Restart = "always";
      };
    };
  };

}
