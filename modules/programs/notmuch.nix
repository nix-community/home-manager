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

  # accepts both user.name = ... or [user] name=...
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


${cfg.extraConfig}
''
# tODO need to pass the actual config
# ${cfg.contactCompletionCommand}
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
      getHooksFolder = mkOption {
        # type = types.nullOr types.path; # precise a folder ?
        # type = types.function;
        default = null;
        # account: account.store.".notmuch/hooks";
        description = "path to the hooks folder to use for a specific account";
      };


      postSyncHook = mkOption {
        default = postSyncCommand;
        description = "Command to run after MRA";
      };

      extraConfig = mkOption {
        type = types.str;
        default = ''
            [maildir]
            synchronize_flags=true
          '';
        description = "string that will be appended to the config";
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.notmuch ];

    home.activation.createNotmuchHooks =
    let
      wrapHook = account: ''
        mkdir -p ${getStore account}/.notmuch/hooks
        ''
        + lib.optionalString  (account.configStore != null) ''
    # buildInputs = [makeWrapper];
          source ${pkgs.makeWrapper}/nix-support/setup-hook

        for hookName in post-new pre-new post-insert
        do
          originalHook=${account.configStore}/$hookName
          destHook=${getStore account}/.notmuch/hooks/$hookName
          if [ -f "$originalHook" ] && [ ! -f "$destHook" ]; then
            makeWrapper "$originalHook" \
              "$destHook" \
            --set NOTMUCH_CONFIG ${getNotmuchConfig account}
          fi

        done
    '';
    in 
    dagEntryAfter [ "createMailStores" ] (
      concatStrings  (map wrapHook config.mail.accounts) 
    )
      # ''
      # ''
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


