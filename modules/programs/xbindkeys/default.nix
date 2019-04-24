##################################################
{ config
, lib
, pkgs
, ...
}:

##################################################
let
#------------------------------------------------#

cfg = config.programs.xbindkeys;

#------------------------------------------------#
in
##################################################

{
  meta.maintainers = [ lib.maintainers.sboosali ];

  #----------------------------#

  options = {
    programs.xbindkeys = import ./options.nix { inherit pkgs lib; };
  };

  #----------------------------#

  config = lib.mkIf cfg.enable {

    home.packages = [ cfg.finalPackage ];

    programs.xbindkeys.finalPackage = cfg.package;
    #TODO# xbindkeysWithPackages cfg.extraGuilePackages;

  };
}