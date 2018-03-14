{ config, lib, pkgs, ... } @ top:

with lib;
with import ../lib/dag.nix { inherit lib; };
with import ../lib/mail.nix { inherit lib config; };

let

  cfg = config.programs.notmuch;

  # best to  so that tags can use it
  postSyncCommand = account:
    ''
      # we export so that hooks use the correct DB
      # (not sure it would work with --config)
      export NOTMUCH_CONFIG=${getNotmuchConfig account}
      ${pkgs.notmuch}/bin/notmuch new
    '';

  # TODO test simple
  # command = 'notmuch address --format=json date:1Y..'
  # TODO might need to add the database too
  # or add --config ?
  # account:
  findContactCommand =  if cfg.contactCompletion == "notmuch address" then ''
command = '${pkgs.notmuch}/bin/notmuch address --format=json --output=recipients date:1Y.. AND from:my@address.org'
regexp = '\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?'
shellcommand_external_filtering = False
  '' else if cfg.contactCompletion == "notmuch address simple" then
  "command = '${pkgs.notmuch}/bin/notmuch address --format=json date:1Y..'"
  else 
    "";



  accountStr = {userName, address, realname, ...} @ account:
    ''
[user]
name=${userName}
primary_email=${address}
# other_email=

[new]
tags=unread;inbox;
ignore=

[search]
exclude_tags=deleted;spam;

[maildir]
synchronize_flags=true

${cfg.contactCompletionCommand}
''
# tODO need to pass the actual config
  ;


  # TODO run notmuch new instead ?
  configFile = mailAccount:
  ''
      [database]
      # todo make it configurable
      path=${getStore mailAccount}

      ${accountStr mailAccount}
  ''
  + cfg.extraConfig
  ;
in
{

  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch";

      # rename getHooksFolder
      getHooks = mkOption {
        type = types.nullOr types.path; # precise a folder ?
        # type = types.function;
        default = null;
        # account: account.store.".notmuch/hooks";
        description = "path to the hooks folder to use for a specific account";
      };

      # see http://alot.readthedocs.io/en/latest/configuration/contacts_completion.html
      contactCompletion = mkOption {
        type = types.enum [ "notmuch address simple" "notmuch address" ];
        default = "notmuch address";
        description = "path to the hooks folder to use for a specific account";
      };

      # TODO make it a function of the account
      contactCompletionCommand = mkOption {
        type = types.str;
        default = findContactCommand;
        description = "Can override what is decided in contactCompletion";
      };

      postSyncHook = mkOption {
        default = postSyncCommand;
        description = "Command to run after MRA";
      };

      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "string that will be appended to the config";
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.notmuch ];


      home.activation.createMailStores = dagEntryBefore [ "linkGeneration" ] ''
        echo 'hello world, notmuch link activation'
      '' 
      ;

      # TODO need to add the hooks

      # Hooks  are  scripts  (or arbitrary executables or symlinks to such) that notmuch invokes before and after certain actions. These scripts reside in the .notmuch/hooks
       # directory within the database directory and must have executable permissions 
      xdg.configFile = map (account: {
        target = "notmuch/notmuch_${account.name}";
        text = configFile account; 
      }) top.config.mail.accounts;
  };
}


