# TODO load template
{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };
with import ../lib/mail.nix { inherit lib config; };

let

  cfg = config.programs.mbsync;

  # TODO move to lib account.mta.postSyncHookCommand
  # postSyncHookCommand = account: 
  #   pkgs.writeScript "postSyncHook.sh" (

  #   lib.optionalString config.programs.notmuch.enable (config.programs.notmuch.postSyncHook account)
  #  + lib.optionalString (account.postSyncHook != null) account.postSyncHook
  # );
  # if (account.postSyncHook != null) then account.postSyncHook else if (config.programs.notmuch.enable) then config.programs.notmuch.postSyncHook else ""
  # );
  generateOfflineimapAlias = account:
    "alias offlineimap-${account.name}='${cfg.fetchMailCommand account}'";
    

  # TODO maybe generate one config per account and load it with -c ?
  # TODO add postsynchook only if notmuch enabled ?
  # TODO allow for user customisation
  # make the path towards config a function ?

# postsynchook= ${postSyncHookCommand account}
# remoteusereval = ${cfg.getLogin account}
	# SSLType IMAPS
	# CertificateFile /etc/ssl/certs/ca-certificates.crt
    # ${if account.imapHost != null then "IMAP" else "Gmail"}
      # ${if (isGmail account) then "Maildir" else "GmailMaildir"}
  accountStr = {name, userName, address, realname, ...} @ account:
    ''
      IMAPAccount ${name}-remote
      # holgerschurig@gmail.com
      User  ${cfg.getPass account}
      PassCmd ${cfg.getPass account}

      IMAPStore ${name}-local
      Account ${name}

      Path ${getStore account}
      # we don't need to specify inbox / trash right ?!
      # Inbox ${getStore account}INBOX

      Channel ${name}
      Master :${name}-remote:
      Slave :${name}-local:
      Patterns *
      Create Both
      SyncState *
      Sync All

      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  configFile = mailAccounts: pkgs.writeText "mbsyncrc" (  ''

    # default settings for all channels
    Fsync no

    CopyArrivalDate yes
    Create Slave
    Sync All
    Expunge Both

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '' 
  + cfg.extraConfig
  );

in

{

  options = {
    programs.mbsync = {
      enable = mkEnableOption "Mbsync";

      # getLogin = mkOption {
      #   # type = types.function;
      #   default = account: "get_pass('${account.name}', 'login')";
      #   description = "function accepting a mail account as parameter";
      # };

      # getPass = mkOption {
      #   # type = types.function;
      #   default = account: "get_pass('${account.name}', 'password')";
      #   description = "function accepting a mail account as parameter";
      # };

      generateShellAliases = mkOption {
        default = generateOfflineimapAlias;
        description = "default theme";
      };

      # needs to be an option to be accessible by mra.fetchMailCommand
      fetchMailCommand = mkOption {
        default = account: 
          "${pythonEnv}/bin/offlineimap -a${account.name}"
        ;
        description = "default theme";
      };

      # run on finish
      # TODO should be per account
      postSyncHookCommand = mkOption {
        # type = types.str;
        default = account: "";
        description = "function accepting a mail account as parameter";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/alot/config.";
      };
    };
  };

  config = mkIf cfg.enable {

    # home.packages =  [
    #   pythonEnv
    # ];

    # create script to retrieve keyring
    # "${config.xdg.configHome}/offlineimap/get_settings.py"
    # home.activation.createAlotScript = dagEntryBefore [ "linkGeneration" ] ''

    # '';

    # todo rely on libsecret instead ? else we need to override offlineimap
    # xdg.configFile."offlineimap/get_settings.py".text = ''
    #   import keyring

    #   def get_pass (service, name):
    #       v = keyring.get_password(service, name)
    #       # print("TEEESSTTT", v)
    #       # print("type", type(v))
    #       return v
    # '';

    # ca s appelle notmuchrc plutot
    home.file.".mbsyncrc".source = configFile config.mail.accounts;
  };
}
