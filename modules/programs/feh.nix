{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.feh;

  disableBinding = func: key: func;
  enableBinding = func: key: "${func} ${toString key}";

in

{
  options.programs.feh = {
    enable = mkEnableOption "feh - a fast and light image viewer";

    buttons = mkOption {
      default = {};
      type = with types; attrsOf (nullOr (either str int));
      example = { zoom_in = 4; zoom_out = "C-4"; };
      description = ''
        Override feh's default mouse button mapping. If you want to disable an
	action, set its value to null.
        See <link xlink:href="https://man.finalrewind.org/1/feh/#x425554544f4e53"/> for
        default bindings and available commands.
      '';
    };

    keybindings = mkOption {
      default = {};
      type = types.attrsOf (types.nullOr types.str);
      example = { zoom_in = "plus"; zoom_out = "minus"; };
      description = ''
        Override feh's default keybindings. If you want to disable a keybinding
	set its value to null.
        See <link xlink:href="https://man.finalrewind.org/1/feh/#x4b455953"/> for
        default bindings and available commands.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = ((filterAttrs (n: v: v == "") cfg.keybindings) == {});
	message = "To disable a keybinding, use `null` instead of an empty string.";
      }
    ];

    home.packages = [ pkgs.feh ];

    xdg.configFile."feh/buttons".text = ''
      ${concatStringsSep "\n" (mapAttrsToList disableBinding (filterAttrs (n: v: v == null) cfg.buttons))}
      ${concatStringsSep "\n" (mapAttrsToList enableBinding (filterAttrs (n: v: v != null) cfg.buttons))}
    '';

    xdg.configFile."feh/keys".text = ''
      ${concatStringsSep "\n" (mapAttrsToList disableBinding (filterAttrs (n: v: v == null) cfg.keybindings))}
      ${concatStringsSep "\n" (mapAttrsToList enableBinding (filterAttrs (n: v: v != null) cfg.keybindings))}
    '';
  };
}
