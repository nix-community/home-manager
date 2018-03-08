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
'';

  # TODO run notmuch new instead ?
  configFile = mailAccount:
  ''
      [database]
      # todo make it configurable
      path=${config.home.homeDirectory}/maildir

      ${accountStr mailAccount}
  '';

  mails = top.config.home.mailAccounts;
  # mails = [];
  genRc = {userName, address, realname, ...} @ account:
  {
    xdg.configFile."notmuch/${userName}".text = configFile account; 
  };

  notmuchRcFiles = mailAccounts:
    lib.lists.foldr (a: b: a // genRc b ) {} mailAccounts;

  toto = notmuchRcFiles  mails;
in
{
# TODO per account specifics
# [new]
# tags=unread;inbox;
# ignore=

  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch";

    };
  };

  # use listToAttrs
  config = mkIf cfg.enable ({
    home.packages = [ pkgs.notmuch ];

    # mapAttrs

    # create folder where to store mails
      # home.activation.createMailStore = dagEntryBefore [ "linkGeneration" ] ''
      #   echo 'hello world, notmuch link activation'
      #   # if ! cmp --quiet \
      #   #     "${configFile}" \
      #   #     "${config.xdg.configHome}/i3/config"; then
      #   #   i3Changed=1
      #   # fi
      # '';

      # ca s appelle notmuchrc plutot
  } // toto);
}


