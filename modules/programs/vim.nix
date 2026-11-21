{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filter
    isBool
    isList
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    sort
    types
    ;

  cfg = config.programs.vim;
  defaultPlugins = [ pkgs.vimPlugins.vim-sensible ];

  inherit (cfg) plugins;

  toVimSetting =
    name: value:
    if value == null then
      ""
    else if isBool value then
      "set " + (if value then "" else "no") + name
    else if isList value then
      "set ${name}=${concatStringsSep "," (map toString value)}"
    else
      "set ${name}=${toString value}";

in
{
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      plugins = mkOption {
        type = types.listOf types.package;
        default = defaultPlugins;
        example = literalExpression "[ pkgs.vimPlugins.YankRing-vim ]";
        description = ''
          List of vim plugins to install. To get a list of supported plugins run:
          {command}`nix-env -f '<nixpkgs>' -qaP -A vimPlugins`.
        '';
      };

      settings = mkOption {
        type = types.attrsOf (
          types.nullOr (
            types.oneOf [
              types.bool
              types.int
              types.str
              (types.listOf (
                types.oneOf [
                  types.str
                  types.int
                ]
              ))
            ]
          )
        );
        default = { };
        example = literalExpression ''
          {
            background = "dark";
            expandtab = true;
            history = 1000;
            number = true;
            shiftwidth = 4;
            tabstop = 4;
            wildignore = [ "*.o" "*~" "*.pyc" ];
          }
        '';
        description = ''
          An attribute set of Vim settings to be converted into {command}`set` commands.
          Booleans are translated to {command}`set <option>` or {command}`set no<option>`.
          Lists are translated to comma-separated strings.
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

      packageConfigurable = mkPackageOption pkgs "vim-full" {
        extraDescription = "Vim package to customize";
        example = "pkgs.vim";
      };

      defaultEditor = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure {command}`vim` as the default
          editor using the {env}`EDITOR` and {env}`VISUAL`
          environment variables.
        '';
      };
    };
  };

  config = (
    let
      settingsFormat =
        let
          lines = mapAttrsToList toVimSetting cfg.settings;
          nonEmptyLines = filter (line: line != "") lines;
        in
        concatStringsSep "\n" (sort (a: b: a < b) nonEmptyLines);

      customRC = ''
        " Generated settings
        ${settingsFormat}

        " Extra configuration
        ${cfg.extraConfig}
      '';

      vim = cfg.packageConfigurable.customize {
        name = "vim";
        vimrcConfig = {
          inherit customRC;
          packages.home-manager.start = plugins;
        };
      };
    in
    mkIf cfg.enable {
      home.packages = [ cfg.package ];

      home.sessionVariables = mkIf cfg.defaultEditor {
        EDITOR = "vim";
        VISUAL = "vim";
      };

      programs.vim = {
        package = vim;
        plugins = defaultPlugins;
      };
    }
  );
}
