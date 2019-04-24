##################################################
{ lib
, pkgs

, cfgProgram                    # « programs.xbindkeys._ »
, cfgService                    # « services.xbindkeys._ »
}:

##################################################
let
#------------------------------------------------#

xbindkeys = ''${cfgProgram.finalPackage}/bin/xbindkeys'';

#------------------------------------------------#

killall = ''${pkgs.killall}/bin/killall'';

#bash = ''${pkgs.stdenv.shell}'';

#------------------------------------------------#
in
##################################################
let
#------------------------------------------------#

default_XBINDKEYSRC_FILE   = ''"$XDG_CONFIG_HOME"/xbindkeys/xbindkeysrc'';
default_XBINDKEYSRC_OPTION = ''-f ${default_XBINDKEYSRC_FILE}'';

# ^ “late-binding” for the xdg environment-variable.

# dslXbindkeysRc    = ''-f "$XDG_CONFIG_HOME"/xbindkeys/xbindkeysrc'';
# schemeXbindkeysRc = ''-fg "$XDG_CONFIG_HOME"/xbindkeys/xbindkeysrc.scm'';



#------------------------------------------------#

XBINDKEYSRC_FILE =

  if   (cfgService.language == "xbindkeys") && (cfgService.config != null)
  then cfgService.config

  else

  if   (cfgService.language == "guile") && (cfgService.configGuile != null)
  then cfgService.configGuile

  else default_XBINDKEYSRC_FILE;

# ^ a filepath

#------------------------------------------------#

XBINDKEYSRC_OPTION =

  if   (cfgService.language == "xbindkeys") && (cfgService.config != null)
  then ''-f ${cfgService.config}''

  else

  if   (cfgService.language == "guile") && (cfgService.configGuile != null)
  then ''-fg ${cfgService.configGuile}''

  else default_XBINDKEYSRC_OPTION;

# ^ a command-line option with its (filepath) argument.

#------------------------------------------------#
in
##################################################

{

  Unit = {
    Description           = "XBindKeys global-keybinding daemon";
    Documentation         = ''man:xbindkeys(1) https://www.nongnu.org/xbindkeys/xbindkeys.html file:/usr/include/X11/keysymdef.h'';
    After                 = [ "environment.target" ];
    PartOf                = [ "graphical-session.target" ];
  # AssertPathExists      = ''${XBINDKEYSRC_FILE}'';
  # StartLimitInterval    = 0;
  };

  Service = {
    ExecStart  = ''${xbindkeys} ${XBINDKEYSRC_OPTION} '';
    ExecReload = ''${killall} -HUP xbindkeys'';
    Type       = "forking";
    Restart    = "on-failure";
    RestartSec = 1;

    # NOTE
    #
    # • « Type= » — The command « xbindkeys -n » means “no-daemon”,
    #   which implies the service should be « Type=simple »;
    #   The command « xbindkeys » means “yes-daemon”,
    #   which implies the service should be « Type=forking ».
    #   If « ExecStart= » is changed,
    #   then « Type= » should be updated too.
    #
    # • « ExecReload= » — should be synchronous (if possible);
    #   however, « kill » is asynchronous.
    #
    # • « kill » is a shell-builtin (c.f. « $ type kill »).
    #   The « Exec*= » fields require absolute-filepaths to executables.
    #   Hence, the shell-builtin is wrapped within a shell-call;
    #   c.f. « ExecReload=bash -l -c '...'  »,
    #   with an absolute-filepath to « .../bin/bash ».
    #
    # • « bash -l -c »:
    #     • « -c STRING » — run the given command.
    #     • « -l » — run as a Login-Shell.
    #

  };

  Install = {
    WantedBy = [ "xsession.target" ];

  };

}

# Links (for maintainers):
#
# • <https://superuser.com/questions/759759/writing-a-service-that-depends-on-xorg>
#

/* TODO...

Environment=''GUILE_PATH=${pkgs.guile?}'';
# Register Nix-Installed Guile packages with XBindKeys.

*/