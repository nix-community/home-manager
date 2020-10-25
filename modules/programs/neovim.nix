{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

  extraPythonPackageType = mkOptionType {
    name = "extra-python-packages";
    description = "python packages in python.withPackages format";
    check = with types;
      (x: if isFunction x then isList (x pkgs.pythonPackages) else false);
    merge = mergeOneOption;
  };

  extraPython3PackageType = mkOptionType {
    name = "extra-python3-packages";
    description = "python3 packages in python.withPackages format";
    check = with types;
      (x: if isFunction x then isList (x pkgs.python3Packages) else false);
    merge = mergeOneOption;
  };

  pluginWithConfigType = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "vim plugin";
      };
      config = mkOption {
        type = types.lines;
        description = "vimscript for this plugin to be placed in init.vim";
        default = "";
      };
    };
  };

  # A function to get the configuration string (if any) from an element of 'plugins'
  pluginConfig = p:
    if builtins.hasAttr "plugin" p && builtins.hasAttr "config" p then ''
      " ${p.plugin.pname} {{{
      ${p.config}
      " }}}
    '' else
      "";

  moduleConfigure = optionalAttrs (cfg.extraConfig != ""
    || (lib.filter (hasAttr "config") cfg.plugins) != [ ]) {
      customRC = cfg.extraConfig
        + pkgs.lib.concatMapStrings pluginConfig cfg.plugins;
    } // optionalAttrs (cfg.plugins != [ ]) {
      packages.home-manager.start = map (x: x.plugin or x) cfg.plugins;
    };
  extraMakeWrapperArgs = lib.optionalString (cfg.extraPackages != [ ])
    ''--prefix PATH : "${lib.makeBinPath cfg.extraPackages}"'';

in {
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

      withPython = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 2 provider. Set to <literal>true</literal> to
          use Python 2 plugins.
        '';
      };

      extraPythonPackages = mkOption {
        type = with types; either extraPythonPackageType (listOf package);
        default = (_: [ ]);
        defaultText = "ps: []";
        example = literalExample "(ps: with ps; [ pandas jedi ])";
        description = ''
          A function in python.withPackages format, which returns a
          list of Python 2 packages required for your plugins to work.
        '';
      };

      withRuby = mkOption {
        type = types.nullOr types.bool;
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
        defaultText = "ps: []";
        example = literalExample "(ps: with ps; [ python-language-server ])";
        description = ''
          A function in python.withPackages format, which returns a
          list of Python 3 packages required for your plugins to work.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.neovim-unwrapped;
        defaultText = literalExample "pkgs.neovim-unwrapped";
        description = "The package to use for the neovim binary.";
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      configure = mkOption {
        type = types.attrs;
        default = { };
        example = literalExample ''
          configure = {
              customRC = $''''
              " here your custom configuration goes!
              $'''';
              packages.myVimPackage = with pkgs.vimPlugins; {
                # loaded on launch
                start = [ fugitive ];
                # manually loadable by calling `:packadd $plugin-name`
                opt = [ ];
              };
            };
        '';
        description = ''
          Generate your init file from your list of plugins and custom commands,
          and loads it from the store via <command>nvim -u /nix/store/hash-vimrc</command>

          </para><para>

          This option is mutually exclusive with <varname>extraConfig</varname>
          and <varname>plugins</varname>.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nocompatible
          set nobackup
        '';
        description = ''
          Custom vimrc lines.

          </para><para>

          This option is mutually exclusive with <varname>configure</varname>.
        '';
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = "[ pkgs.shfmt ]";
        description = "Extra packages available to nvim.";
      };

      plugins = mkOption {
        type = with types; listOf (either package pluginWithConfigType);
        default = [ ];
        example = literalExample ''
          with pkgs.vimPlugins; [
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

          </para><para>

          This option is mutually exclusive with <varname>configure</varname>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.configure == { } || moduleConfigure == { };
      message = "The programs.neovim option configure is mutually exclusive"
        + " with extraConfig and plugins.";
    }];

    home.packages = [ cfg.finalPackage ];

    programs.neovim.finalPackage = pkgs.wrapNeovim cfg.package {
      inherit (cfg)
        extraPython3Packages withPython3 extraPythonPackages withPython
        withNodeJs withRuby viAlias vimAlias;

      extraMakeWrapperArgs = extraMakeWrapperArgs;
      configure = cfg.configure // moduleConfigure;
    };

    programs.bash.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.fish.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.zsh.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
  };
}
