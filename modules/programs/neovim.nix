{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatMapStringsSep
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

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

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
      viAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink {command}`vi` to {command}`nvim` binary.
        '';
      };

      vimAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink {command}`vim` to {command}`nvim` binary.
        '';
      };

      vimdiffAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Alias {command}`vimdiff` to {command}`nvim -d`.
        '';
      };

      defaultEditor = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure {command}`nvim` as the default
          editor using the {env}`EDITOR` and {env}`VISUAL`
          environment variables.
        '';
      };

      # Providers & Runtimes
      withNodeJs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable node provider. Set to `true` to
          use Node plugins.
        '';
      };

      withPerl = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable perl provider. Set to `true` to
          use Perl plugins.
        '';
      };

      withPython3 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 3 provider. Set to `true` to
          use Python 3 plugins.
        '';
      };

      withRuby = mkOption {
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Enable ruby provider.
        '';
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

      autowrapRuntimeDeps = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to automatically wrap the binary with the runtime dependencies of the plugins.
        '';
      };

      waylandSupport = mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        defaultText = literalExpression "pkgs.stdenv.isLinux";
        description = ''
          Whether to enable Wayland clipboard support.
        '';
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

      extraLuaConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          vim.opt.nobackup = true
        '';
        description = ''
          Custom lua lines.
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
                default = "viml";
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
      allPlugins =
        cfg.plugins
        ++ lib.optional cfg.coc.enable {
          type = "viml";
          plugin = cfg.coc.package;
          config = cfg.coc.pluginConfig;
          optional = false;
        };

      defaultPlugin = {
        type = "viml";
        plugin = null;
        config = null;
        optional = false;
        runtime = { };
      };

      # transform all plugins into a standardized attrset
      pluginsNormalized = map (
        x: defaultPlugin // (if (x ? plugin) then x else { plugin = x; })
      ) allPlugins;

      suppressNotVimlConfig = p: if p.type != "viml" then p // { config = null; } else p;

      # Lua & Python Package Resolution
      luaPackages = cfg.finalPackage.unwrapped.lua.pkgs;
      resolvedExtraLuaPackages = cfg.extraLuaPackages luaPackages;

      # Wrapper Arguments Construction
      extraMakeWrapperArgs = optionals (cfg.extraPackages != [ ]) [
        "--suffix"
        "PATH"
        ":"
        (lib.makeBinPath cfg.extraPackages)
      ];

      extraMakeWrapperLuaCArgs = optionals (resolvedExtraLuaPackages != [ ]) [
        "--suffix"
        "LUA_CPATH"
        ";"
        (concatMapStringsSep ";" luaPackages.getLuaCPath resolvedExtraLuaPackages)
      ];

      extraMakeWrapperLuaArgs = optionals (resolvedExtraLuaPackages != [ ]) [
        "--suffix"
        "LUA_PATH"
        ";"
        (concatMapStringsSep ";" luaPackages.getLuaPath resolvedExtraLuaPackages)
      ];

      neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
        inherit (cfg)
          extraPython3Packages
          withPython3
          withRuby
          withPerl
          viAlias
          vimAlias
          ;
        withNodeJs = cfg.withNodeJs || cfg.coc.enable;
        plugins = map suppressNotVimlConfig pluginsNormalized;
        customRC = cfg.extraConfig;
      };

      wrappedNeovim' = pkgs.wrapNeovimUnstable cfg.package (
        neovimConfig
        // {
          inherit (cfg)
            extraName
            autowrapRuntimeDeps
            waylandSupport
            withNodeJs
            ;
          wrapperArgs =
            neovimConfig.wrapperArgs
            ++ cfg.extraWrapperArgs
            ++ extraMakeWrapperArgs
            ++ extraMakeWrapperLuaCArgs
            ++ extraMakeWrapperLuaArgs;
          wrapRc = false;
        }
      );
    in
    {
      programs.neovim = {
        generatedConfigViml = neovimConfig.neovimRcContent;

        generatedConfigs =
          let
            grouped = lib.lists.groupBy (x: x.type) pluginsNormalized;
            configsOnly = lib.foldl (acc: p: if p.config != null then acc ++ [ p.config ] else acc) [ ];
          in
          lib.mapAttrs (name: vals: concatMapStringsSep "\n" (configsOnly vals)) grouped;

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

      xdg.configFile =
        let
          hasLuaConfig = lib.hasAttr "lua" config.programs.neovim.generatedConfigs;
          luaRcContent =
            lib.optionalString (
              wrappedNeovim'.initRc != ""
            ) "vim.cmd [[source ${pkgs.writeText "nvim-init-home-manager.vim" wrappedNeovim'.initRc}]]\n"
            + config.programs.neovim.extraLuaConfig
            + lib.optionalString hasLuaConfig config.programs.neovim.generatedConfigs.lua;
        in
        lib.mkMerge (
          # writes runtime
          (map (x: x.runtime) pluginsNormalized)
          ++ [
            {
              "nvim/init.lua" = mkIf (luaRcContent != "") { text = luaRcContent; };

              "nvim/coc-settings.json" = mkIf cfg.coc.enable {
                source = jsonFormat.generate "coc-settings.json" cfg.coc.settings;
              };
            }
          ]
        );
    }
  );
}
