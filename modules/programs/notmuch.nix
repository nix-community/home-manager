{ config, lib, pkgs, mailAccounts, ... } @ top:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.notmuch;

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
''
# tODO need to pass the actual config
  + lib.optionalString (cf.contactCompletion == "notmuch address") ''
command = 'notmuch address --format=json --output=recipients date:1Y.. AND from:my@address.org'
regexp = '\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?'
shellcommand_external_filtering = False
  ''
  ;


  # TODO run notmuch new instead ?
  configFile = mailAccount:
  ''
      [database]
      # todo make it configurable
      path=${mailAccount.store}

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
        # type = types.function;
        default = account: account.store.".notmuch/hooks";
        description = "path to the hooks folder to use for a specific account";
      };
      # rename getHooksFolder
      contactCompletion = mkOption {
        type = types.enum [ "notmuch address" ];
        # type = types.function;
        default = "notmuch address";
        description = "path to the hooks folder to use for a specific account";
      };
    # function that returns specific hooks
      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "string that will be appended to the config";
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.notmuch ];


    # create folder where to store mails
      home.activation.createMailStores = dagEntryBefore [ "linkGeneration" ] ''
        echo 'hello world, notmuch link activation'
        # if ! cmp --quiet \
        #     "${configFile}" \
        #     "${config.xdg.configHome}/i3/config"; then
        #   i3Changed=1
        # Link the hooks in their respective stores
        # our own hook folders
        ${map (account: (account.store.".notmuch/hooks".source = getHooks account)
        # {
        #   target = "";
        #   text = "";
        # }
          )  top.config.home.mailAccounts}
      '';

      # Hooks  are  scripts  (or arbitrary executables or symlinks to such) that notmuch invokes before and after certain actions. These scripts reside in the .notmuch/hooks
       # directory within the database directory and must have executable permissions 
      xdg.configFile = map (account: {
        target = "notmuch/notmuch_${account.name}";
        text = configFile account; 
      }) top.config.home.mailAccounts;
  };
}


