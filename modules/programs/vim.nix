{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ "sensible" ];

  knownSettings = {
    background = types.enum [ "dark" "light" ];
    copyindent = types.bool;
    expandtab = types.bool;
    hidden = types.bool;
    history = types.int;
    ignorecase = types.bool;
    modeline = types.bool;
    number = types.bool;
    relativenumber = types.bool;
    shiftwidth = types.int;
    smartcase = types.bool;
    tabstop = types.int;
  };

  vimSettingsType = types.submodule {
    options =
      let
        opt = name: type: mkOption {
          type = types.nullOr type;
          default = null;
          visible = false;
        };
      in
        mapAttrs opt knownSettings;
  };

  setExpr = name: value:
    let
      v =
        if isBool value then (if value then "" else "no") + name
        else name + "=" + toString value;
    in
      optionalString (value != null) ("set " + v);

in

{
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      lineNumbers = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to show line numbers. DEPRECATED: Use
          <varname>programs.vim.settings.number</varname>.
        '';
      };

      tabSize = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 4;
        description = ''
          Set tab size and shift width to a specified number of
          spaces. DEPRECATED: Use
          <varname>programs.vim.settings.tabstop</varname> and
          <varname>programs.vim.settings.shiftwidth</varname>.
        '';
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = defaultPlugins;
        example = [ "YankRing" ];
        description = ''
          List of vim plugins to install. To get a list of supported plugins run:
          <command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A vimPlugins</command>.
        '';
      };

      settings = mkOption {
        type = vimSettingsType;
        default = {};
        example = literalExample ''
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
          ${concatStringsSep "\n" (
            mapAttrsToList (n: v: ''
              <row>
                <entry><varname>${n}</varname></entry>
                <entry>${v.description}</entry>
              </row>
            '') knownSettings
          )}
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
    };
  };

  config = (
    let
      customRC = ''
        ${concatStringsSep "\n" (
          filter (v: v != "") (
          mapAttrsToList setExpr (
          builtins.intersectAttrs knownSettings cfg.settings)))}

        ${cfg.extraConfig}
      '';

      vim = pkgs.vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = customRC;
        vimrcConfig.vam.knownPlugins = pkgs.vimPlugins;
        vimrcConfig.vam.pluginDictionaries = [
          { names = defaultPlugins ++ cfg.plugins; }
        ];
      };

    in mkIf cfg.enable (mkMerge [
      {
        programs.vim.package = vim;
        home.packages = [ cfg.package ];
      }

      (mkIf (cfg.lineNumbers != null) {
        warnings = [
          ("'programs.vim.lineNumbers' is deprecated, "
            + "use 'programs.vim.settings.number'")
        ];

        programs.vim.settings.number = cfg.lineNumbers;
      })

      (mkIf (cfg.tabSize != null) {
        warnings = [
          ("'programs.vim.tabSize' is deprecated, use "
            + "'programs.vim.settings.tabstop' and "
            + "'programs.vim.settings.shiftwidth'")
        ];

        programs.vim.settings.tabstop = cfg.tabSize;
        programs.vim.settings.shiftwidth = cfg.tabSize;
      })
    ])
  );
}
