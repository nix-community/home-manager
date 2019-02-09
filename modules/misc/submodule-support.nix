{ lib, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options.submoduleSupport = {
    enable = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = ''
        Whether the Home Manager module system is used as a submodule
        in, for example, NixOS or nix-darwin.
      '';
    };
  };
}
