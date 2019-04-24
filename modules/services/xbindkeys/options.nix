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

  enable = lib.mkEnableOption "the XBindKeys daemon";

  #----------------------------#

  language = lib.mkOption {

    type = T.nullOr (T.enum [ "xbindkeys" "guile" ]);

    default = null;
    example = "guile";

    description = ''
'';

  };

  #----------------------------#

  configGuile = lib.mkOption {

    type = T.either T.path T.str;

    default = ''"$XDG_CONFIG_HOME"/xbindkeys/xbindkeysrc.scm'';

    description = ''
    '';

  };

  #----------------------------#

  config = lib.mkOption {

    type = T.either T.path T.str;

    default = ''"$XDG_CONFIG_HOME"/xbindkeys/xbindkeysrc'';

    description = ''
    '';

  };

  #----------------------------#

  extraConfigGuile = lib.mkOption {

    type = T.lines;

    default = [];
    example = ''
(define (run-xbindkeys_show) 
  (run-command "xbindkeys_show"))

;; Run « xbindkeys_show » when you press « C-S-q »:

(xbindkey-function '(control alt shift q) 
                   run-xbindkeys_show)
'';

    description = ''
    '';

  };

  #----------------------------#

  extraConfig = lib.mkOption {

    type = T.lines;

    default = [];
    example = ''
# Run « xbindkeys_show » when you press « C-S-q »:

"xbindkeys_show" 
  control+shift + q
'';

   description = ''
    '';

  };

  #----------------------------#

  finalLanguage = lib.mkOption {
    type = T.string;
    visible = false;
    readOnly = true;
    description = ''The XBindKeys config language.'';
  };

  #----------------------------#

  finalConfig = lib.mkOption {
    type = T.string;
    visible = false;
    readOnly = true;
    description = ''The XBindKeys config file.'';
  };

  #----------------------------#
}