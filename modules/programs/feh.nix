{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.feh;

  disableBinding = func: key: func;
  enableBinding = func: key: "${func} ${key}";

in

{
  options.programs.feh = {
    enable = mkEnableOption "feh - a fast and light image viewer";

    keybindings = mkOption {
      default = {};
      type = types.attrsOf types.str;
      example = { zoom_in = "plus"; zoom_out = "minus"; };
      description = ''
        Set keybindings.
        See <link xlink:href="https://man.finalrewind.org/1/feh/#x4b455953"/> for
        default bindings and available commands.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.feh ];

    xdg.configFile."feh/keys".text = ''
      # Disable default keybindings
      ${concatStringsSep "\n" (mapAttrsToList disableBinding cfg.keybindings)}

      # Enable new keybindings
      ${concatStringsSep "\n" (mapAttrsToList enableBinding cfg.keybindings)}
    '';
  };
}
