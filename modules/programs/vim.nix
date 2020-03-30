{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ pkgs.vimPlugins.vim-sensible ];

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
      if isDerivation p then
        [ p ]
      else
        optional (isString p && hasAttr p vpkgs) vpkgs.${p};
  in concatMap getPkg cfg.plugins;

in {
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      plugins = mkOption {
        type = with types; listOf (either str package);
        default = defaultPlugins;
        example = literalExample "[ pkgs.vimPlugins.YankRing ]";
        description = ''
          List of vim plugins to install. To get a list of supported plugins run:
          <command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A vimPlugins</command>.

          </para><para>

          Note: String values are deprecated, please use actual packages.
        '';
      };

      settings = mkOption {
        type = vimSettingsType;
        default = { };
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
    };
  };

  config = (let
    customRC = ''
      ${concatStringsSep "\n" (filter (v: v != "") (mapAttrsToList setExpr
        (builtins.intersectAttrs knownSettings cfg.settings)))}

      ${cfg.extraConfig}
    '';

    vim = pkgs.vim_configurable.customize {
      name = "vim";
      vimrcConfig = {
        inherit customRC;

        packages.home-manager.start = plugins;
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

    programs.vim = {
      package = vim;
      plugins = defaultPlugins;
    };
  });
}
