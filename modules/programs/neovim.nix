{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionals
    types
    ;

  cfg = config.programs.neovim;

  inherit
    (
      (import ../lib/file-type.nix {
        inherit (config.home) homeDirectory;
        inherit lib pkgs;
      })
    )
    fileType
    ;

  inherit (pkgs) neovimUtils;
  jsonFormat = pkgs.formats.json { };

  pluginTypeStateVersion = lib.hm.deprecations.mkStateVersionOptionDefault {
    inherit (config.home) stateVersion;
    since = "26.05";
    optionPath = [
      "programs"
      "neovim"
      "plugins"
      "PLUGIN"
      "type"
    ];
    legacy.value = "viml";
    current.value = "lua";
  };
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "neovim" "extraLuaConfig" ]
      [ "programs" "neovim" "initLua" ]
    )
  ];

  options = {
    programs.neovim = {
      enable = mkEnableOption "Neovim";

      package = mkPackageOption pkgs "neovim" { default = "neovim-unwrapped"; };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      # Aliases
      viAlias = mkEnableOption "symlinking {command}`vi` to {command}`nvim`";

      vimAlias = mkEnableOption "symlinking {command}`vim` to {command}`nvim`";

      vimdiffAlias = mkEnableOption "aliasing {command}`vimdiff` to {command}`nvim -d`";

      defaultEditor = mkEnableOption "configuring {command}`nvim` as the default editor using the {env}`EDITOR` and {env}`VISUAL` environment variables";

      # Providers & Runtimes
      withNodeJs = mkEnableOption "the Node provider. Set to `true` to use Node plugins";

      withPerl = mkEnableOption "the Perl provider. Set to `true` to use Perl plugins";

      withPython3 = mkEnableOption "the Python 3 provider. Set to `true` to use Python 3 plugins" // {
        inherit
          (lib.hm.deprecations.mkStateVersionOptionDefault {
            inherit (config.home) stateVersion;
            since = "26.05";
            optionPath = [
              "programs"
              "neovim"
              "withPython3"
            ];
            legacy.value = true;
            current.value = false;
          })
          default
          defaultText
          ;
      };

      withRuby = mkEnableOption "the Ruby provider" // {
        inherit
          (lib.hm.deprecations.mkStateVersionOptionDefault {
            inherit (config.home) stateVersion;
            since = "26.05";
            optionPath = [
              "programs"
              "neovim"
              "withRuby"
            ];
            legacy.value = true;
            current.value = false;
          })
          default
          defaultText
          ;
      };

      extraPython3Packages = mkOption {
        type = types.functionTo (types.listOf types.package);
        default = _: [ ];
        defaultText = literalExpression "ps: [ ]";
        example = literalExpression "pyPkgs: with pyPkgs; [ python-language-server ]";
        description = ''
          The extra Python 3 packages required for your plugins to work.
          This option accepts a function that takes a Python 3 package set as an argument,
          and selects the required Python 3 packages from this package set.
          See the example for more info.
        '';
      };

      extraLuaPackages = mkOption {
        type = types.functionTo (types.listOf types.package);
        default = _: [ ];
        defaultText = literalExpression "ps: [ ]";
        example = literalExpression "luaPkgs: with luaPkgs; [ luautf8 ]";
        description = ''
          The extra Lua packages required for your plugins to work.
          This option accepts a function that takes a Lua package set as an argument,
          and selects the required Lua packages from this package set.
          See the example for more info.
        '';
      };

      # Wrapper Configuration
      extraName = mkOption {
        type = types.str;
        default = "";
        description = ''
          Extra name appended to the wrapper package name.
        '';
      };

      autowrapRuntimeDeps = mkEnableOption "automatically wrapping runtime dependencies of plugins" // {
        default = true;
      };

      waylandSupport = mkEnableOption "Wayland clipboard support" // {
        default = pkgs.stdenv.isLinux;
        defaultText = literalExpression "pkgs.stdenv.isLinux";
      };

      extraWrapperArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [
            "--suffix"
            "LIBRARY_PATH"
            ":"
            "''${lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.zlib ]}"
            "--suffix"
            "PKG_CONFIG_PATH"
            ":"
            "''${lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ pkgs.stdenv.cc.cc pkgs.zlib ]}"
          ]
        '';
        description = ''
          Extra arguments to be passed to the neovim wrapper.
          This option sets environment variables required for building and running binaries
          with external package managers like mason.nvim.
        '';
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.shfmt ]";
        description = "Extra packages available to nvim.";
      };

      # Configuration & Plugins
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nobackup
        '';
        description = ''
          Custom vimrc lines.
        '';
      };

      initLua = mkOption {
        type = types.lines;
        default = "";
        example = lib.literalExpression ''
          let
              nvimEarlyInit = lib.mkOrder 500 "set rtp+=vim.opt.rtp:prepend('/home/user/myplugin')";
              nvimLateInit = lib.mkAfter "vim.opt.signcolumn = 'auto:1-3'";
          in
              lib.mkMerge [ nvimEarlyInit nvimLateInit ];
        '';
        description = ''
          Content to be added to {file}`init.lua`.

          Automatically contains the [advised plugin config](https://nixos.org/manual/nixpkgs/stable/#neovim-custom-configuration)

          To specify the order, use `lib.mkOrder`, `lib.mkBefore`, `lib.mkAfter`.
        '';
      };

      plugins =
        let
          pluginWithConfigType = types.submodule {
            options = {
              config = mkOption {
                type = types.nullOr types.lines;
                description = "Script to configure this plugin. The scripting language should match type.";
                default = null;
              };

              type = mkOption {
                type = types.either (types.enum [
                  "lua"
                  "viml"
                  "teal"
                  "fennel"
                ]) types.str;
                description = "Language used in config. Configurations are aggregated per-language.";
                default = pluginTypeStateVersion.effectiveDefault;
                inherit (pluginTypeStateVersion) defaultText;
              };

              optional = mkEnableOption "optional" // {
                description = "Don't load by default (load with :packadd)";
              };

              plugin = mkPackageOption pkgs.vimPlugins "plugin" {
                default = null;
                example = "pkgs.vimPlugins.nvim-treesitter";
                pkgsText = "pkgs.vimPlugins";
              };

              runtime = mkOption {
                default = { };
                # passing actual "${xdg.configHome}/nvim" as basePath was a bit tricky
                # due to how fileType.target is implemented
                type = fileType "programs.neovim.plugins._.runtime" "{var}`xdg.configHome/nvim`" "nvim";
                example = literalExpression ''
                  { "ftplugin/c.vim".text = "setlocal omnifunc=v:lua.vim.lsp.omnifunc"; }
                '';
                description = ''
                  Set of files that have to be linked in nvim config folder.
                '';
              };
            };
          };

        in
        mkOption {
          type = types.listOf (types.either types.package pluginWithConfigType);
          default = [ ];
          example = literalExpression ''
            with pkgs.vimPlugins;
            [
              yankring
              vim-nix
              { plugin = vim-startify;
                config = "let g:startify_change_to_vcs_root = 0";
              }
            ]
          '';
          description = ''
            List of vim plugins to install optionally associated with
            configuration to be placed in init.vim.

            This option is mutually exclusive with {var}`configure`.
          '';
        };

      coc = {
        enable = mkEnableOption "Coc";

        package = mkPackageOption pkgs "coc-nvim" {
          default = [
            "vimPlugins"
            "coc-nvim"
          ];
        };

        settings = mkOption {
          inherit (jsonFormat) type;
          default = { };
          example = literalExpression ''
            {
              "suggest.noselect" = true;
              "suggest.enablePreview" = true;
              "suggest.enablePreselect" = false;
              "suggest.disableKind" = true;
              languageserver = {
                haskell = {
                  command = "haskell-language-server-wrapper";
                  args = [ "--lsp" ];
                  rootPatterns = [
                    "*.cabal"
                    "stack.yaml"
                    "cabal.project"
                    "package.yaml"
                    "hie.yaml"
                  ];
                  filetypes = [ "haskell" "lhaskell" ];
                };
              };
            }
          '';
          description = ''
            Extra configuration lines to add to
            {file}`$XDG_CONFIG_HOME/nvim/coc-settings.json`
            See
            <https://github.com/neoclide/coc.nvim/wiki/Using-the-configuration-file>
            for options.
          '';
        };

        pluginConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Script to configure CoC. Must be viml.";
        };
      };

      # Generated / Read-Only
      generatedConfigViml = mkOption {
        type = types.lines;
        visible = true;
        readOnly = true;
        description = ''
          Generated vimscript config.
        '';
      };

      generatedConfigs = mkOption {
        type = types.attrsOf types.lines;
        visible = true;
        readOnly = true;
        example = literalExpression ''
          {
            viml = '''
              " Generated by home-manager
              map <leader> ,
            ''';

            lua = '''
              -- Generated by home-manager
              vim.opt.background = "dark"
            ''';
          }
        '';
        description = ''
          Generated configurations with as key their language (set via type).
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    let
      legacyPluginTypeWarnings = lib.hm.deprecations.mkStateVersionListSubmoduleWarnings {
        inherit (config.home) stateVersion;
        since = "26.05";
        baseWarning = pluginTypeStateVersion.warning;
        definitions = options.programs.neovim.plugins.definitionsWithLocations;
        shouldWarnEntry = lib.hm.deprecations.mkListEntryOmittedFieldPredicate {
          omittedField = "type";
          triggerField = "config";
        };
        describeEntry =
          entry:
          if entry.value ? plugin && entry.value.plugin != null then
            "plugin `${lib.getName entry.value.plugin}`"
          else
            "a plugin entry";
        extraEntryWarning =
          _entry:
          ''Set `type = "viml"` or `type = "lua"` on that plugin entry to make the config language explicit.'';
      };

      allPlugins =
        cfg.plugins
        ++ lib.optional cfg.coc.enable {
          type = "viml";
          plugin = cfg.coc.package;
          config = cfg.coc.pluginConfig;
          optional = false;
        };

      defaultPlugin = {
        type = pluginTypeStateVersion.effectiveDefault;
        plugin = null;
        config = null;
        optional = false;
        runtime = { };
      };

      # transform all plugins into a standardized attrset
      pluginsNormalized = map (
        x: defaultPlugin // (if x ? plugin then x else { plugin = x; })
      ) allPlugins;

      # remove attributes not understood by nixpkgs' "makeVimPackageInfo"
      suppressIncompatibleConfig =
        p:
        lib.filterAttrs (
          n: _v:
          builtins.elem n [
            "plugin"
            "optional"
            "config"
          ]
        ) (if p.type != "viml" then p // { config = null; } else p);

      # Wrapper Arguments Construction
      extraMakeWrapperArgs = optionals (cfg.extraPackages != [ ]) [
        "--suffix"
        "PATH"
        ":"
        (lib.makeBinPath cfg.extraPackages)
      ];

      nixpkgsCompatiblePlugins = map suppressIncompatibleConfig pluginsNormalized;
      vimPackageInfo = neovimUtils.makeVimPackageInfo nixpkgsCompatiblePlugins;

      wrappedNeovim' =
        (pkgs.wrapNeovimUnstable cfg.package {
          withNodeJs = cfg.withNodeJs || cfg.coc.enable;
          plugins = nixpkgsCompatiblePlugins;

          inherit (cfg)
            extraLuaPackages
            extraName
            withPython3
            withRuby
            withPerl
            viAlias
            vimAlias
            autowrapRuntimeDeps
            waylandSupport
            ;

          extraPython3Packages =
            ps: (cfg.extraPython3Packages ps) ++ (lib.concatMap (f: f ps) vimPackageInfo.pluginPython3Packages);
          neovimRcContent = cfg.extraConfig;
          wrapperArgs = cfg.extraWrapperArgs ++ extraMakeWrapperArgs;
          wrapRc = false;
        }).overrideAttrs
          {

            # nixpkgs implementation dependend: avoid nixpkgs adding rtp/packpath wrapping arguments
            packpathDirs.myNeovimPackages = {
              start = [ ];
              opt = [ ];
            };
          };

      # This is a hack to avoid breaking config for users that dont want an init.lua to get generated
      # See https://github.com/nix-community/home-manager/pull/8734
      # we basically check if the generated wrapper lua config has any user-set config
      # if not HM avoids creating an init.lua
      # this makes the logic harder to understand and maintain so hopefully we can find a way out
      wrapperHasUserConfig = wrappedNeovim'.luaRcContent != wrappedNeovim'.providerLuaRc;
    in
    {
      warnings = legacyPluginTypeWarnings;

      programs.neovim = {
        generatedConfigViml = cfg.extraConfig;

        generatedConfigs =
          let
            grouped = lib.groupBy (x: x.type) pluginsNormalized;
            configsOnly = lib.foldl (acc: p: if p.config != null then acc ++ [ p.config ] else acc) [ ];
          in
          lib.mapAttrs (_name: vals: lib.concatStringsSep "\n" (configsOnly vals)) grouped;

        finalPackage = wrappedNeovim';
      };

      home = {
        packages = [ cfg.finalPackage ];

        sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };

        shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
      };

      programs.neovim.extraPackages = mkIf cfg.autowrapRuntimeDeps vimPackageInfo.runtimeDeps;

      programs.neovim.extraWrapperArgs = mkIf (!wrapperHasUserConfig) [
        "--add-flags"
        ''--cmd 'lua dofile("${pkgs.writeText "wrapper-init-lua" wrappedNeovim'.luaRcContent}")' ''
      ];

      programs.neovim.initLua =
        let
          # using default 'foldmarker', to be used with foldmethod=marker
          foldedLuaBlock =
            title: content:
            if (content != "") then
              ''
                -- ${title} {{{
                ${content}
                -- }}}
              ''
            else
              null;
        in
        lib.mkMerge [
          (lib.mkIf wrapperHasUserConfig (
            # we want it to appear rather early
            lib.mkOrder 200 wrappedNeovim'.luaRcContent
          ))
          (lib.mkIf (lib.hasAttr "lua" cfg.generatedConfigs && cfg.generatedConfigs.lua != "") (
            lib.mkAfter (foldedLuaBlock "user-associated plugin config" cfg.generatedConfigs.lua)
          ))

        ];

      # link the packpath in expected folder so that even unwrapped neovim can pick
      # home-manager's plugins
      xdg.dataFile."nvim/site/pack/hm" =
        let
          packpathDirs.hm = vimPackageInfo.vimPackage;
        in
        {
          enable = allPlugins != [ ];
          source = "${pkgs.neovimUtils.packDir packpathDirs}/pack/hm";
        };

      xdg.configFile = lib.mkMerge (
        # writes runtime
        (map (x: x.runtime) pluginsNormalized)
        ++ [
          {
            "nvim/init.lua" = mkIf (cfg.initLua != "") {
              text = cfg.initLua;
            };

            "nvim/coc-settings.json" = mkIf cfg.coc.enable {
              source = jsonFormat.generate "coc-settings.json" cfg.coc.settings;
            };
          }
        ]
      );
    }
  );
}
