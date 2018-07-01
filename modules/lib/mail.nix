{ config, lib }:
{
  getStore = account:
    if account.store != null then account.store else config.mail.maildir + "/${account.name}";

    isGmail = account:
      if account.imapHost != null then
      (builtins.match ".*\.gmail\..*" account.imapHost) != null
      else false
      ;

  getNotmuchConfig = account:
    # "${config.xdg.configFile}/notmuch/notmuch_${account.name}";

    "$XDG_CONFIG_HOME/notmuch/notmuch_${account.name}";
}
