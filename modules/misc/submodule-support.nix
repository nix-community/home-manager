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

    externalPackageInstall = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = ''
        Whether the packages of {option}`home.packages` are
        installed separately from the Home Manager activation script.
        In NixOS, for example, this may be accomplished by installing
        the packages through
        {option}`users.users.‹name?›.packages`.
      '';
    };
  };

  config = {
    # To make it easier for the end user to override the values in the
    # configuration depending on the installation method, we set default values
    # for the arguments that are defined in the NixOS/nix-darwin modules.
    #
    # Without these defaults, these attributes would simply not exist, and the
    # module system can not inform modules about their non-existence; see
    # https://github.com/NixOS/nixpkgs/issues/311709#issuecomment-2110861842
    _module.args = {
      osConfig = mkDefault null;
      nixosConfig = mkDefault null;
      darwinConfig = mkDefault null;
    };
  };
}
