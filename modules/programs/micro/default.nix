{ config, lib, pkgs, ... }:
let
  cfg = config.programs.micro;
  dir = ".config/micro";
in {
  meta.maintainers = [ maintainers.sivizius ];

  ###### interface
  options = {
    programs.micro = {
      enable = lib.mkEnableOption
        "micro – a modern easy-to-use intuitive terminal-based text editor.";
      bindings = import ./bindings.nix lib;
      colorschemes = import ./colorschemes.nix lib;
      extraSettings = import ./extraSettings.nix lib;
      plugins = import ./plugins.nix lib;
      settings = import ./settings.nix lib;
    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    home = let
      colorschemes = lib.mapAttrs' (name: configuration:
        lib.nameValuePair ("${dir}/colorschemes/${name}.micro") ({
          text = lib.concatStringsSep "" (lib.mapAttrsToList
            (variable: value: ''
              color-link ${variable} "${value}"
            '') configuration);
        })) cfg.colorschemes;
      plugins = lib.genAttrs cfg.plugins (name: true);
      settings = cfg.settings // cfg.extraSettings // plugins;
    in {
      packages = [ pkgs.micro ];
      file = {
        "${dir}/bindings.json".text = builtins.toJSON cfg.bindings;
        "${dir}/settings.json".text = builtins.toJSON settings;
      } // colorschemes;
    };
  };
}
