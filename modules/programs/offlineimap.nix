# TODO load template
{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };
with import ../lib/mail.nix { inherit lib config; };

let

  cfg = config.programs.offlineimap;

  # TODO move to lib account.mta.postSyncHookCommand
  postSyncHookCommand = account: 
    pkgs.writeScript "postSyncHook.sh" (

    lib.optionalString config.programs.notmuch.enable (config.programs.notmuch.postSyncHook account)
   + lib.optionalString (account.postSyncHook != null) account.postSyncHook
  );
  # if (account.postSyncHook != null) then account.postSyncHook else if (config.programs.notmuch.enable) then config.programs.notmuch.postSyncHook else ""
  # );

  generateOfflineimapAlias = account:
    

  # TODO maybe generate one config per account and load it with -c ?
  # TODO add postsynchook only if notmuch enabled ?
  # TODO allow for user customisation
  # make the path towards config a function ?
  accountStr = {name, userName, address, realname, ...} @ account:
    ''

[Account ${name}]
localrepository = ${name}-local
remoterepository = ${name}-remote
# interval between updates (in minutes)
autorefresh=0
# in bytes
maxsize=2000000
# in daysA
maxage=10
synclabels= yes
postsynchook= ${postSyncHookCommand account}

[Repository ${name}-local]
# HACK
type = ${if (isGmail account) then "Maildir" else "GmailMaildir"}
localfolders = ${getStore account}

[Repository ${name}-remote]
type = ${if account.imapHost != null then "IMAP" else "Gmail"}
${if account.imapHost != null then "remotehost = "+ account.imapHost else ""}
remoteusereval = ${cfg.getLogin account}
remotepasseval = ${cfg.getPass account}
realdelete = yes
maxconnections = 3
ssl= yes
# seens to work without it ?
sslcacertfile= /etc/ssl/certs/ca-certificates.crt
# newer offlineimap > 6.5.4 needs this
# cert_fingerprint = 89091347184d41768bfc0da9fad94bfe882dd358
# name translations would need to be done in both repositories, but reverse
# prevent sync with All mail folder since it duplicates mail
folderfilter = lambda foldername: foldername not in ['[Gmail]/All Mail','[Gmail]/Spam','[Gmail]/Important']
      '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  configFile = mailAccounts: pkgs.writeText "offlineimap.conf" (  ''
  [general]
  accounts = gmail
  maxsyncaccounts= 4
  socktimeout = 10
  pythonfile = $XDG_CONFIG_HOME/offlineimap/get_settings.py

  metadata = $XDG_DATA_HOME/offlineimap
  # choose one from machineui, blinkenlights, quiet, ttyui, basic
  ui = ttyui

  [mbnames]
  #generate mailboxes file for mutt
  enabled = yes
  filename = $XDG_CONFIG_HOME/mutt/mailboxes
  header = "mailboxes *\nmailboxes !\n"
  peritem = mailboxes =%(accountname)s/%(foldername)s
  sep = "\n"
  footer = "\n"


    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '' 
  + cfg.extraConfig
  );

in

{

  options = {
    programs.offlineimap = {
      enable = mkEnableOption "Offlineimap";

      getLogin = mkOption {
        # type = types.function;
        default = account: "get_pass('${account.name}', 'login')";
        description = "function accepting a mail account as parameter";
      };

      getPass = mkOption {
        # type = types.function;
        default = account: "get_pass('${account.name}', 'password')";
        description = "function accepting a mail account as parameter";
      };

      # generateAliases = mkOption {
      #   default = generateOfflineimapAlias;
      #   description = "default theme";
      # };

      fetchMailCommand = mkOption {
        default = account: 
          "offlineimap -a ${account.name}"
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

    home.packages = let
      pythonEnv = pkgs.python3.withPackages(ps: with ps; [ secretstorage keyring pygobject3 pkgs.offlineimap]);
      in [
      # pkgs.offlineimap 
      # pkgs.python3Packages.toPythonApplication (pkgs.offlineimap.overrideAttrs (oldAttrs: {
        # USERNAME 	echo " nix-shell -p python3Packages.secretstorage -p python36Packages.keyring -p python36Packages.pygobject3"
        # propagatedBuildInputs = with pkgs.python3Packages; oldAttrs.propagatedBuildInputs ++ ;
      # }))
      pythonEnv
    ];

    # create script to retrieve keyring
    # "${config.xdg.configHome}/offlineimap/get_settings.py"
    home.activation.createAlotScript = dagEntryBefore [ "linkGeneration" ] ''

    '';

    # todo rely on libsecret instead ? else we need to override offlineimap
    xdg.configFile."offlineimap/get_settings.py".text = ''
      import keyring

      def get_pass (service, name):
          v = keyring.get_password(service, name)
          # print("TEEESSTTT", v)
          # print("type", type(v))
          return v
    '';

    # ca s appelle notmuchrc plutot
    xdg.configFile."offlineimap/config".source = configFile config.mail.accounts;
  };
}
