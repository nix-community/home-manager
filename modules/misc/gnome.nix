{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.gnome;

  inherit (config.lib) dag;

  customKeybinding = types.submodule {
    options = {
      binding = mkOption {
        type = types.str;
        description = "The key combination that triggers the command";
      };
      command = mkOption {
        type = types.str;
        description = "The command to execute";
      };
    };
  };

  # File containing the bindings in JSON format expected by the management script.
  bindingsJson = pkgs.writeText "gnome-custom-keybindings.json" (builtins.toJSON
    (lib.mapAttrsToList (name: value: {
      inherit name;
      inherit (value) binding command;
    }) cfg.customKeybindings));

  updateScript = ./gnome_update_custom_keybindings.py;

  python = "${pkgs.python3.withPackages (p: [ p.pygobject3 ])}/bin/python";

in {
  meta.maintainers = [ maintainers.liff ];

  options = {
    gnome = {
      customKeybindings = mkOption {
        type = types.attrsOf customKeybinding;
        default = { };
        example = literalExample ''
          {
            "New Terminal" = {
              binding = "<Super>Return";
              command = "gnome-terminal";
            };
          }
        '';
        description = ''
          Custom keybindings to add to GNOME desktop. The name of the attribute appears
          as the name of the keybinding.</para>

          <para>The keybindings are stored in DConf path
          <literal>/org/gnome/settings-daemon/plugins/media-keys/home-manager-managed-keybindings/</literal>.
        '';
      };
    };
  };

  config = {
    home.activation.gnomeCustomKeybindings =
      dag.entryAfter [ "dconfSettings" ] ''
        ${python} ${updateScript} < ${bindingsJson}
      '';
  };
}
