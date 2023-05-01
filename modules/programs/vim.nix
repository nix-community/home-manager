{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ pkgs.vimPlugins.vim-sensible ];

  pluginWithConfigType = types.submodule {
    options = {
      config = mkOption {
        type = types.nullOr types.lines;
        description = "Script to configure this plugin.";
        default = null;
      };

      plugin = mkOption {
        type = types.package;
        description = "vim plugin";
      };
    };
  };

  knownSettings = {
    background = types.enum [ "dark" "light" ];
    backupdir = types.listOf types.str;
    copyindent = types.bool;
    directory = types.listOf types.str;
    expandtab = types.bool;
    hidden = types.bool;
    history = types.int;
    ignorecase = types.bool;
    modeline = types.bool;
    mouse = types.enum [ "n" "v" "i" "c" "h" "a" "r" ];
    mousefocus = types.bool;
    mousehide = types.bool;
    mousemodel = types.enum [ "extend" "popup" "popup_setpos" ];
    number = types.bool;
    relativenumber = types.bool;
    shiftwidth = types.int;
    smartcase = types.bool;
    tabstop = types.int;
    undodir = types.listOf types.str;
    undofile = types.bool;
  };

  vimSettingsType = types.submodule {
    options = let
      opt = name: type:
        mkOption {
          type = types.nullOr type;
          default = null;
          visible = false;
        };
    in mapAttrs opt knownSettings;
  };

  setExpr = name: value:
    let
      v = if isBool value then
        (if value then "" else "no") + name
      else
        "${name}=${
          if isList value then concatStringsSep "," value else toString value
        }";
    in optionalString (value != null) ("set " + v);

  plugins = let
    vpkgs = pkgs.vimPlugins;
    getPkg = p:
      if isDerivation p || p ? plugin then
        [ p ]
      else
        optional (isString p && hasAttr p vpkgs) vpkgs.${p};
  in concatMap getPkg cfg.plugins;
in {
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      plugins = mkOption {
        type = with types;
          listOf (oneOf [
            package
            pluginWithConfigType
            str
          ]);
        default = [ ];
        example = literalExpression ''
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

      settings = mkOption {
        type = vimSettingsType;
        default = { };
        example = literalExpression ''
          {
            expandtab = true;
            history = 1000;
            background = "dark";
          }
        '';
        description = ''
          At attribute set of Vim settings. The attribute names and
          corresponding values must be among the following supported
          options.

          <informaltable frame="none"><tgroup cols="1"><tbody>
          ${concatStringsSep "\n" (mapAttrsToList (n: v: ''
            <row>
              <entry><varname>${n}</varname></entry>
              <entry>${v.description}</entry>
            </row>
          '') knownSettings)}
          </tbody></tgroup></informaltable>

          See the Vim documentation for detailed descriptions of these
          options. Note, use <varname>extraConfig</varname> to
          manually set any options not listed above.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nocompatible
          set nobackup
        '';
        description = "Custom .vimrc lines";
      };

      package = mkOption {
        type = types.package;
        description = "Resulting customized vim package";
        readOnly = true;
      };

      packageConfigurable = mkOption {
        type = types.package;
        description = "Vim package to customize";
        default = pkgs.vim-full or pkgs.vim_configurable;
        defaultText = literalExpression "pkgs.vim-full";
        example = literalExpression "pkgs.vim";
      };

      defaultEditor = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure <command>vim</command> as the default
          editor using the <envar>EDITOR</envar> environment variable.
        '';
      };
    };
  };

  config = let
    defaultPlugin = {
      plugin = null;
      config = null;
    };

    pluginsNormalized =
      map (x: defaultPlugin // (if (x ? plugin) then x else { plugin = x; }))
      cfg.plugins;

    pluginList = catAttrs "plugin" pluginsNormalized;
    pluginConfigs = catAttrs "config" pluginsNormalized;

    customRC = ''
      ${concatStringsSep "\n" (remove "" (mapAttrsToList setExpr
        (builtins.intersectAttrs knownSettings cfg.settings)))}

      ${cfg.extraConfig}

      ${concatStringsSep "\n" (remove null pluginConfigs)}
    '';

    vim = cfg.packageConfigurable.customize {
      name = "vim";
      vimrcConfig = {
        inherit customRC;

        packages.home-manager.start = pluginList;
      };
    };
  in mkIf cfg.enable {
    assertions = let
      packagesNotFound =
        filter (p: isString p && (!hasAttr p pkgs.vimPlugins)) cfg.plugins;
    in [{
      assertion = packagesNotFound == [ ];
      message = "Following VIM plugin not found in pkgs.vimPlugins: ${
          concatMapStringsSep ", " (p: ''"${p}"'') packagesNotFound
        }";
    }];

    warnings = let stringPlugins = filter isString cfg.plugins;
    in optional (stringPlugins != [ ]) ''
      Specifying VIM plugins using strings is deprecated, found ${
        concatMapStringsSep ", " (p: ''"${p}"'') stringPlugins
      } as strings.
    '';

    home.packages = [ cfg.package ];

    home.sessionVariables = mkIf cfg.defaultEditor { EDITOR = "vim"; };

    programs.vim = {
      package = vim;
      plugins = defaultPlugins;
    };
  };
}
