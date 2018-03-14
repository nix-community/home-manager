{ config, lib }:
{
  getStore = account:
    if account.store != null then account.store else config.mail.maildir + "/${account.name}";


  getNotmuchConfig = account:
    "${config.xdg.configFile}/notmuch/notmuch_${account.name}";
}
