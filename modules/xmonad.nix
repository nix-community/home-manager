{ config, pkgs, lib, ... }:

with lib;
with import ./lib/dag.nix { inherit lib; };

let
  cfg = config.xmonad;
  homefile = ".xmonad/xmonad.hs";
  xmonad = pkgs.xmonad-with-packages.override {
    ghcWithPackages = cfg.haskellPackages.ghcWithPackages;
    packages = self: cfg.extraPackages self ++
                     optionals cfg.enableContribAndExtras
                     [ self.xmonad-contrib self.xmonad-extras ];
  };
in
{
  options.xmonad = {
    enable = mkEnableOption "xmonad";
    haskellPackages = mkOption {
      default = pkgs.haskellPackages;
      defaultText = "pkgs.haskellPackages";
      example = literalExample "pkgs.haskell.packages.ghc784";
      description = ''
        haskellPackages used to build Xmonad and other packages.
        This can be used to change the GHC version used to build
        Xmonad and the packages listed in
        <varname>extraPackages</varname>.
      '';
    };

    extraPackages = mkOption {
      default = self: [];
      defaultText = "self: []";
      example = literalExample ''
        haskellPackages: [
          haskellPackages.xmonad-contrib
          haskellPackages.monad-logger
        ]
      '';
      description = ''
        Extra packages available to ghc when rebuilding Xmonad. The
        value must be a function which receives the attrset defined
        in <varname>haskellPackages</varname> as the sole argument.
      '';
    };

    enableContribAndExtras = mkOption {
      default = false;
      type = types.bool;
      description = "Enable xmonad-{contrib,extras} in Xmonad.";
    };

    config = mkOption {
      type = types.nullOr types.path;
      example = literalExample ''
        pkgs.writeText "xmonad.hs" '''
          import XMonad
          main = xmonad def
              { terminal    = "urxvt"
              , modMask     = mod4Mask
              , borderWidth = 3
              }
        '''
      '';
      description = ''
        The config to be used for Xmonad. This must be an absolute path or null,
        in which case ~/.xmonad/xmonad.hs doesn't get managed by HM.

        Some options are:

        - Directly import a file with <literal>config = ./xmonad.hs;</literal>.
        - Use <literal>pkgs.writeText "xmonad" '''&lt;config&gt;'''</literal>.
        - Substitute @val@'s in a file with direct store binaries with
        the substitute bash function.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      xsession.windowManager = mkDefault "${xmonad}/bin/xmonad";

      home.packages = [ xmonad ];
    }
    (mkIf (cfg.config != null) {

      home.file.${homefile}.source = cfg.config;

      home.activation.checkXMonad = dagEntryBefore [ "linkGeneration" ] ''
        if ! cmp ${cfg.config} $HOME/${homefile} >/dev/null; then
          _XMONAD_CHANGED=1
        else
          _XMONAD_CHANGED=0
        fi
      '';

      home.activation.applyXMonad = dagEntryAfter [ "linkGeneration" ] ''
        if [ $_XMONAD_CHANGED = 1 ]; then
          echo Recompiling Xmonad
          ${xmonad}/bin/xmonad --recompile
          echo Restarting Xmonad
          ${xmonad}/bin/xmonad --restart
        fi
      '';
    })
  ]);
}
