{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

  fileType = (import ../lib/file-type.nix {
    inherit (config.home) homeDirectory;
    inherit lib pkgs;
  }).fileType;

  jsonFormat = pkgs.formats.json { };

  extraPython3PackageType = mkOptionType {
    name = "extra-python3-packages";
    description = "python3 packages in python.withPackages format";
    check = with types;
      (x: if isFunction x then isList (x pkgs.python3Packages) else false);
    merge = mergeOneOption;
  };

  # Currently, upstream Neovim is pinned on Lua 5.1 for LuaJIT support.
  # This will need to be updated if Neovim ever migrates to a newer
  # version of Lua.
  extraLua51PackageType = mkOptionType {
    name = "extra-lua51-packages";
    description = "lua5.1 packages in lua5_1.withPackages format";
    check = with types;
      (x: if isFunction x then isList (x pkgs.lua51Packages) else false);
    merge = mergeOneOption;
  };

  pluginWithConfigType = types.submodule {
    options = {
      config = mkOption {
        type = with types; nullOr str;
        default = null;
        description =
          "Script to configure this plugin. The scripting language should match type.";
      };

      type = mkOption {
        type = types.str;
        description =
          "Language used in config. Configurations are aggregated per-language.";
        default = "viml";
      };

      optional = mkEnableOption "optional" // {
        description = "Don't load by default (load with :packadd)";
      };

      plugin = mkOption {
        type = types.package;
        description = "Package providing the plugin";
      };

      runtime = mkOption {
        default = { };
        # passing actual "${xdg.configHome}/nvim" as basePath was a bit tricky
        # due to how fileType.target is implemented
        type = fileType "<varname>xdg.configHome/nvim</varname>" "nvim";
        example = literalExpression ''
          { "ftplugin/c.vim".text = "setlocal omnifunc=v:lua.vim.lsp.omnifunc"; }
        '';
        description = ''
          Set of files that have to be linked in nvim config folder.
        '';
      };
    };
  };

  languageType = types.submodule {
    options = {
      extension = mkOption {
        type = types.str;
        description = "File extension this language uses, not including dot.";
        example = "fnl";
      };
      luaPackages = mkOption {
        type = with types; either extraLua51PackageType (listOf package);
        default = [ ];
        example = literalExpression ''
          with pkgs.lua51Packages [ fennel ];
        '';
        description = "Lua packages required to support this language.";
      };
      vimPlugins = mkOption {
        type = with types;
          listOf (coercedTo package (v: { plugin = v; }) pluginWithConfigType);
        default = [ ];
        description = "Vim plugins required to support this language.";
        example = literalExpression ''
          with pkgs.vimPlugins; [ nvim-moonwalk ];
        '';
      };
      enableScript = mkOption {
        type = with types; nullOr str;
        default = null;
        description =
          "Lua script required to enable support for this language.";
        example = literalExpression ''
          require("moonwalk").add_loader("fnl", function(src, path)
              return require("fennel").compileString(src, { filename = path })
          end)
        '';
      };
      importScript = mkOption {
        type = with types; functionTo str;
        default = n: ''
          require('${n}')
        '';
        # Kinda ugly, but the only way I could get a require('${fileName}') literal
        defaultText = literalExpression ''
          fileName: "require(${"'"}''${fileName}')"
        '';
        description = ''
          Function returning the statement which lua will use to import
          this language's config.

          The provided variable does not include file extension.
        '';
      };
    };
  };

  langVimPlugins =
    flatten (mapAttrsToList (_: lang: lang.vimPlugins) cfg.configLanguages);
  allPlugins = cfg.plugins ++ langVimPlugins ++ optional cfg.coc.enable {
    type = "viml";
    plugin = cfg.coc.package;
    config = cfg.coc.pluginConfig;
    optional = false;
    runtime = { };
  };

  langLuaPackages =
    flatten (mapAttrsToList (_: lang: lang.luaPackages) cfg.configLanguages);
  allLuaPackages = cfg.extraLuaPackages ++ langLuaPackages;

  extraMakeWrapperArgs = optionalString (cfg.extraPackages != [ ])
    ''--suffix PATH : "${makeBinPath cfg.extraPackages}"'';
  extraMakeWrapperLuaCArgs = optionalString (allLuaPackages != [ ]) ''
    --suffix LUA_CPATH ";" "${
      concatMapStringsSep ";" pkgs.lua51Packages.getLuaCPath allLuaPackages
    }"'';
  extraMakeWrapperLuaArgs = optionalString (allLuaPackages != [ ]) ''
    --suffix LUA_PATH ";" "${
      concatMapStringsSep ";" pkgs.lua51Packages.getLuaPath allLuaPackages
    }"'';

in {
  imports = [
    (mkRemovedOptionModule [ "programs" "neovim" "generatedConfigViml" ]
      "programs.neovim.generatedConfigViml has been replaced with programs.neovim.generatedConfigs.viml")
    (mkRemovedOptionModule [ "programs" "neovim" "withPython" ]
      "Python2 support has been removed from neovim.")
    (mkRemovedOptionModule [ "programs" "neovim" "extraPythonPackages" ]
      "Python2 support has been removed from neovim.")
    (mkRemovedOptionModule [ "programs" "neovim" "configure" ] ''
      programs.neovim.configure is deprecated.
            Other programs.neovim options can override its settings or ignore them.
            Please use the other options at your disposal:
              configure.packages.*.opt  -> programs.neovim.plugins = [ { plugin = ...; optional = true; }]
              configure.packages.*.start  -> programs.neovim.plugins = [ { plugin = ...; }]
              configure.customRC -> programs.neovim.extraConfig
    '')
  ];

  options = {
    programs.neovim = {
      enable = mkEnableOption "Neovim";

      viAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink <command>vi</command> to <command>nvim</command> binary.
        '';
      };

      vimAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink <command>vim</command> to <command>nvim</command> binary.
        '';
      };

      vimdiffAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Alias <command>vimdiff</command> to <command>nvim -d</command>.
        '';
      };

      withNodeJs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable node provider. Set to <literal>true</literal> to
          use Node plugins.
        '';
      };

      withRuby = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable ruby provider.
        '';
      };

      withPython3 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 3 provider. Set to <literal>true</literal> to
          use Python 3 plugins.
        '';
      };

      extraPython3Packages = mkOption {
        type = with types; either extraPython3PackageType (listOf package);
        default = (_: [ ]);
        defaultText = literalExpression "ps: [ ]";
        example = literalExpression "(ps: with ps; [ python-language-server ])";
        description = ''
          A function in python.withPackages format, which returns a
          list of Python 3 packages required for your plugins to work.
        '';
      };

      extraLuaPackages = mkOption {
        type = with types; either extraLua51PackageType (listOf package);
        default = [ ];
        defaultText = literalExpression "[ ]";
        example = literalExpression "(ps: with ps; [ luautf8 ])";
        description = ''
          A function in lua5_1.withPackages format, which returns a
          list of Lua packages required for your plugins to work.
        '';
      };

      generatedConfigs = mkOption {
        type = types.attrsOf types.str;
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
          }'';
        description = ''
          Generated configurations with their language as key.
          From plugins configurations (using "type") and extraConfig.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.neovim-unwrapped;
        defaultText = literalExpression "pkgs.neovim-unwrapped";
        description = "The package to use for the neovim binary.";
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      extraConfig = mkOption {
        type = with types; coercedTo lines (x: { viml = x; }) (attrsOf lines);
        default = { };
        example = literalExpression ''
          {
            viml = "set nobackup";
            lua = "vim.keymap.set("n", "gd", vim.lsp.buf.definition)";
          }
        '';
        description = ''
          Attribute set of configuration lines, for each supported language.
          If provided as a string, viml is assumed.
        '';
      };

      configLanguages = mkOption {
        description = ''
          Configuration languages supported by neovim.
          </para><para>
          Supports viml (vimscript) and lua by default. The example shows
          how to enable support for fennel using moonwalk.
          </para><para>
          Consider using lib.mkOptionDefault to extend or override default
          languages instead of specifying all of them from scratch.
        '';
        type = with types; attrsOf languageType;
        defaultText = literalExpression ''
          {
            viml = {
              extension = "vim";
              importScript = file: '''
                vim.cmd 'runtime vim/''${file}.vim'
              ''';
            };
            lua = {
              extension = "lua";
            };
          }
        '';
        default = {
          viml = {
            extension = "vim";
            importScript = file: ''
              vim.cmd 'runtime vim/${file}.vim'
            '';
          };
          lua = { extension = "lua"; };
        };
        example = literalExpression ''
          lib.mkOptionDefault {
            fennel = {
              extension = "fnl";
              luaPackages = with pkgs.lua51Packages; [ fennel ];
              vimPlugins = with pkgs.vimPlugins; [ nvim-moonwalk ];
              enableScript = '''
                require("moonwalk").add_loader("fnl", function(src, path)
                    return require("fennel").compileString(src, { filename = path })
                end)
              ''';
              };
            }
        '';
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "[ pkgs.shfmt ]";
        description = "Extra packages available to nvim.";
      };

      extraRuntime = mkOption {
        default = { };
        # passing actual "${xdg.configHome}/nvim" as basePath was a bit tricky
        # due to how fileType.target is implemented
        type = fileType "<varname>xdg.configHome/nvim</varname>" "nvim";
        example = literalExpression ''
          { "ftplugin/c.vim".text = "setlocal omnifunc=v:lua.vim.lsp.omnifunc"; }
        '';
        description = ''
          Set of files that have to be linked in nvim config folder.
        '';
      };

      plugins = mkOption {
        type = with types;
          listOf (coercedTo package (v: { plugin = v; }) pluginWithConfigType);
        default = [ ];
        example = literalExpression ''
          with pkgs.vimPlugins; [
            yankring
            vim-nix
            {
              plugin = vim-startify;
              config = "let g:startify_change_to_vcs_root = 0";
            }
            {
              plugin = nvim-lspconfig;
              type = "lua";
              config = '''
                local lspconfig = require("lspconfig")
                lspconfig.rnix.setup{}
                lspconfig.pylsp.setup{}
              ''';
            }
          ]
        '';
        description = ''
          List of vim plugins to install. May be optionally associated with
          configuration to be placed in the respective language file.
        '';
      };

      coc = {
        enable = mkEnableOption "Coc";

        package = mkOption {
          type = types.package;
          default = pkgs.vimPlugins.coc-nvim;
          defaultText = literalExpression "pkgs.vimPlugins.coc-nvim";
          description = "The package to use for the CoC plugin.";
        };

        settings = mkOption {
          type = jsonFormat.type;
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
            };
          '';
          description = ''
            Extra configuration lines to add to
            <filename>$XDG_CONFIG_HOME/nvim/coc-settings.json</filename>
            See
            <link xlink:href="https://github.com/neoclide/coc.nvim/wiki/Using-the-configuration-file" />
            for options.
          '';
        };

        pluginConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Script to configure CoC. Must be viml.";
        };
      };
    };
  };

  config = let
    suppressNotVimlConfig = plugin:
      if plugin.type != "viml" then plugin // { config = null; } else plugin;

    neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
      inherit (cfg) extraPython3Packages withPython3 withRuby viAlias vimAlias;
      withNodeJs = cfg.withNodeJs || cfg.coc.enable;
      plugins = map suppressNotVimlConfig allPlugins;
      customRC = cfg.extraConfig.viml or "";
    };
  in mkIf cfg.enable {
    assertions = let
      undefinedLangs = subtractLists (attrNames cfg.configLanguages)
        (attrNames cfg.generatedConfigs);
    in [{
      assertion = undefinedLangs == [ ];
      message = if (any (l: l == "lua" || l == "viml") undefinedLangs) then ''
        The neovim configuration is using vimscript or lua, but they are not present in `programs.neovim.configLanguages`.
        You probably meant to use lib.mkOptionDefault when setting it.
      '' else ''
        Languages [${
          concatStringsSep "," undefinedLangs
        }] found in neovim configuration, but not defined in `programs.neovim.configLanguages`.
      '';
    }];

    # Generate config for each supported config language
    programs.neovim.generatedConfigs = let
      concatLines = concatStringsSep "\n";
      getCfgs = plugins: filter (c: c != null) (map (p: p.config) plugins);
      groupedPlugins = lists.groupBy (p: p.type) allPlugins;
      pluginConfigs =
        mapAttrs (_: plugins: concatLines (getCfgs plugins)) groupedPlugins;
    in zipAttrsWith (_: concatLines) [ pluginConfigs cfg.extraConfig ];

    home.packages = [ cfg.finalPackage ];

    xdg.configFile = mkMerge ((map (plugin: plugin.runtime) allPlugins)
      ++ [ (cfg.extraRuntime) ] ++
      # Make a config file for each configLang (if it's not empty) and import it on init.lua
      (mapAttrsToList (langName: langConfig:
        let
          langExtension = cfg.configLanguages.${langName}.extension;
          langImportScript = cfg.configLanguages.${langName}.importScript;
          langFilePath =
            "nvim/${langExtension}/home-manager-${langName}.${langExtension}";
        in mkIf (langConfig != "") {
          ${langFilePath}.text = langConfig;
          "nvim/init.lua".text = ''
            -- ${config.xdg.configFile.${langFilePath}.source}
            ${langImportScript "home-manager-${langName}"}
          '';
        }) cfg.generatedConfigs) ++
      # Add support for all configLanguages
      (mapAttrsToList (langName: langOpts:
        mkIf (langOpts.enableScript != null) {
          "nvim/init.lua".text = langOpts.enableScript;
        }) cfg.configLanguages) ++ [{
          "nvim/coc-settings.json" = mkIf cfg.coc.enable {
            source = jsonFormat.generate "coc-settings.json" cfg.coc.settings;
          };
        }]);

    programs.neovim.finalPackage = pkgs.wrapNeovimUnstable cfg.package
      (neovimConfig // {
        wrapperArgs = (escapeShellArgs neovimConfig.wrapperArgs) + " "
          + extraMakeWrapperArgs + " " + extraMakeWrapperLuaCArgs + " "
          + extraMakeWrapperLuaArgs;
        wrapRc = false;
      });

    programs.bash.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.fish.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.zsh.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
  };
}
