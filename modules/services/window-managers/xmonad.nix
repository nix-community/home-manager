{ pkgs }: { config, lib, ... }:

with lib;

let

  cfg = config.xmonad;

  xmonad = pkgs.xmonad-with-packages.override {
    ghcWithPackages = cfg.haskellPackages.ghcWithPackages;
    packages = self:
      cfg.extraPackages self
      ++ optionals cfg.enableContribAndExtras [
        self.xmonad-contrib self.xmonad-extras
      ];
  };

in

{
  options = {
    xmonad = {
      enable = mkEnableOption "xmonad window manager";

      haskellPackages = mkOption {
        default = pkgs.haskellPackages;
        defaultText = "pkgs.haskellPackages";
        example = literalExample "pkgs.haskell.packages.ghc784";
        description = ''
          The <varname>haskellPackages</varname> used to build xmonad
          and other packages. This can be used to change the GHC
          version used to build xmonad and the packages listed in
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
          Extra packages available to GHC when rebuilding xmonad. The
          value must be a function which receives the attribute set
          defined in <varname>haskellPackages</varname> as the sole
          argument.
        '';
      };

      enableContribAndExtras = mkOption {
        default = false;
        type = types.bool;
        description = "Enable xmonad-{contrib,extras} in xmonad.";
      };

      config = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExample ''
          pkgs.writeText "xmonad.hs" '''
            import XMonad
            main = xmonad defaultConfig
                { terminal    = "urxvt"
                , modMask     = mod4Mask
                , borderWidth = 3
                }
          '''
        '';
        description = ''
          The configuration file to be used for xmonad. This must be
          an absolute path or <literal>null</literal> in which case
          <filename>~/.xmonad/xmonad.hs</filename> will not be managed
          by Home Manager.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    command = "${xmonad}/bin/xmonad";
  };
}
