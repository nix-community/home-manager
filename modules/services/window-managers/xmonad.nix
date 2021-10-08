{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.xmonad;

  xmonad = pkgs.xmonad-with-packages.override {
    ghcWithPackages = cfg.haskellPackages.ghcWithPackages;
    packages = self:
      cfg.extraPackages self ++ optionals cfg.enableContribAndExtras [
        self.xmonad-contrib
        self.xmonad-extras
      ];
  };

in {
  options = {
    xsession.windowManager.xmonad = {
      enable = mkEnableOption "xmonad window manager";

      haskellPackages = mkOption {
        default = pkgs.haskellPackages;
        defaultText = literalExpression "pkgs.haskellPackages";
        example = literalExpression "pkgs.haskell.packages.ghc784";
        description = ''
          The <varname>haskellPackages</varname> used to build xmonad
          and other packages. This can be used to change the GHC
          version used to build xmonad and the packages listed in
          <varname>extraPackages</varname>.
        '';
      };

      extraPackages = mkOption {
        default = self: [ ];
        defaultText = "self: []";
        example = literalExpression ''
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
        example = literalExpression ''
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
          </para>
          <para>
          If this option is set to a non-<literal>null</literal> value,
          recompilation of xmonad outside of Home Manager (e.g. via
          <command>xmonad --recompile</command>) will fail.
        '';
      };

      libFiles = mkOption {
        type = types.attrsOf (types.oneOf [ types.path ]);
        default = { };
        example = literalExpression ''
          {
            "Tools.hs" = pkgs.writeText "Tools.hs" '''
               module Tools where
               screenshot = "scrot"
             ''';
          }
        '';
        description = ''
          Additional files that will be saved in
          <filename>~/.xmonad/lib/</filename> and included in the configuration
          build. The keys are the file names while the values are paths to the
          contents of the files.
        '';
      };
    };
  };

  config = let

    xmonadBin = "${
        pkgs.runCommandLocal "xmonad-compile" {
          nativeBuildInputs = [ xmonad ];
        } ''
          mkdir -p $out/bin

          export XMONAD_CONFIG_DIR="$(pwd)/xmonad-config"
          export XMONAD_DATA_DIR="$(pwd)/data"
          export XMONAD_CACHE_DIR="$(pwd)/cache"

          mkdir -p "$XMONAD_CONFIG_DIR/lib" "$XMONAD_CACHE_DIR" "$XMONAD_DATA_DIR"

          cp ${cfg.config} xmonad-config/xmonad.hs

          declare -A libFiles
          libFiles=(${
            concatStringsSep " "
            (mapAttrsToList (name: value: "['${name}']='${value}'")
              cfg.libFiles)
          })
          for key in "''${!libFiles[@]}"; do
            cp "''${libFiles[$key]}" "xmonad-config/lib/$key";
          done

          xmonad --recompile

          # The resulting binary name depends on the arch and os
          # https://github.com/xmonad/xmonad/blob/56b0f850bc35200ec23f05c079eca8b0a1f90305/src/XMonad/Core.hs#L565-L572
          mv "$XMONAD_DATA_DIR/xmonad-${pkgs.hostPlatform.system}" $out/bin/
        ''
      }/bin/xmonad-${pkgs.hostPlatform.system}";

  in mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (hm.assertions.assertPlatform "xsession.windowManager.xmonad" pkgs
          platforms.linux)
      ];

      home.packages = [ (lowPrio xmonad) ];

      home.file = mapAttrs' (name: value:
        attrsets.nameValuePair (".xmonad/lib/" + name) { source = value; })
        cfg.libFiles;
    }

    (mkIf (cfg.config == null) {
      xsession.windowManager.command = "${xmonad}/bin/xmonad";
    })

    (mkIf (cfg.config != null) {
      xsession.windowManager.command = xmonadBin;
      home.file.".xmonad/xmonad.hs".source = cfg.config;
      home.file.".xmonad/xmonad-${pkgs.hostPlatform.system}" = {
        source = xmonadBin;
        onChange = ''
          # Attempt to restart xmonad if X is running.
          if [[ -v DISPLAY ]]; then
            ${config.xsession.windowManager.command} --restart
          fi
        '';
      };
    })

  ]);
}
