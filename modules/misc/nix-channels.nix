{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix-channels;
in

{
  meta.maintainers = [ maintainers.gerschtli ];

  options = {
    nix-channels = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = literalExample ''
        {
          nixos = "https://nixos.org/channels/nixos-19.03";
        };
      '';
      description = ''
        List of channels to be added to <filename>~/.nix-channels</filename>.

        </para><para>

        Note: As part of nix' shell init script, <filename>~/.nix-channels</filename>
        will always be created if it does not exists.  This means for the first time
        enabling this module, you have to run <command>home-manager</command> with the
        <command>-b</command> flag to backup the automatically generated
        <filename>~/.nix-channels</filename>.
      '';
    };
  };

  config = mkIf (cfg != {}) {
    home = {
      file.".nix-channels".text =
        (concatStringsSep "\n" (mapAttrsToList (name: url: "${url} ${name}") cfg)) + "\n";
    };
  };
}
