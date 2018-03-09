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
in
{

  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.notmuch ];


    # create folder where to store mails
      # home.activation.createMailStore = dagEntryBefore [ "linkGeneration" ] ''
      #   echo 'hello world, notmuch link activation'
      #   # if ! cmp --quiet \
      #   #     "${configFile}" \
      #   #     "${config.xdg.configHome}/i3/config"; then
      #   #   i3Changed=1
      #   # fi
      # '';
      xdg.configFile = map (account: {
        target = "notmuch/notmuch_${account.name}";
        text = configFile account; 
      }) top.config.home.mailAccounts;
  };
}


