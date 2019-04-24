##################################################
{ lib
, pkgs
}: 

##################################################
let
#------------------------------------------------#

T = lib.types;

#------------------------------------------------#
in
##################################################
{

  enable = lib.mkEnableOption "XBindKeys";

  #----------------------------#

  package = lib.mkOption {

    type = T.package;

    default     = pkgs.xbindkeys;
    defaultText = ''pkgs.xbindkeys'';

    description = ''Which XBindKeys package to use.'';

  };

  #----------------------------#

  finalPackage = lib.mkOption {
    type = T.package;
    visible = false;
    readOnly = true;
    description = ''The XBindKeys package (e.g. used by <option>services.xbindkeys</option>).'';
    #TODO# ''The XBindKeys package, including any extra Guile packages.'';
  };

}