##################################################
{ config
, lib
, pkgs
, ...
}:

##################################################
let
#------------------------------------------------#

cfgService = config.services.xbindkeys;
cfgProgram = config.programs.xbindkeys;

#------------------------------------------------#
in
##################################################

{
  meta.maintainers = [ lib.maintainers.sboosali ];

  #----------------------------#

  options = { services.xbindkeys = import ./options.nix { inherit pkgs lib; }; };

  #----------------------------#

  config = lib.mkIf cfgService.enable {

    home.packages = [ pkgs.xbindkeys ];

    systemd.user.services.xbindkeys = import ./service.nix { inherit pkgs lib; inherit cfgService cfgProgram; };

    assertions = [{
        assertion = cfgProgram.enable;
        message = ''The XBindKeys service's module requires {{{ programs.xbindkeys.enable = true; }}}.'';
    }];

  };
}