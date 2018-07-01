{ config, lib, pkgs, ... } @ top:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;

  notmuchConfig = account: "$XDG_CONFIG_HOME/notmuch/notmuch_${account.name}";

  generateNotmuchAlias = {name, ...} @ account:
  {
    name = "alot-${name}";
    # -c $XDG_CONFIG_HOME/alot/alot-${name}
    #  -n ${notmuchConfig account}
    value = "export NOTMUCH_CONFIG=${notmuchConfig account}; ${pkgs.alot}/bin/alot"; 
  };
 
  # TODO test simple
  # command = 'notmuch address --format=json date:1Y..'
  # TODO might need to add the database too
  # or add --config ?
  contactCompletionStr = let
    
      # command="";
      # --config ${notmuchConfig account}
    in
    account: 
    ''
      [[[abook]]]
      type = shellcommand
      command = '' + (
    if account.contactCompletion == "notmuch address" then ''
      '${pkgs.bash}/bin/bash -c "${pkgs.notmuch}/bin/notmuch  address --format=json --output=recipients  date:1Y.."'
    regexp = '\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?'
    shellcommand_external_filtering = False
    '' else if account.contactCompletion == "notmuch --config ${notmuchConfig account} address simple" then
    "'${pkgs.notmuch}/bin/notmuch address --format=json date:1Y..'"
    else 
      "");


  # bindingsStr = fetchMailCommand:
  # ''
  #   [bindings]
  #   % = "shellescape ${account.mra.fetchMailCommand account} ; refresh"
  # '';

  # TODO add contact completion
  # https://alot.readthedocs.io/en/latest/configuration/contacts_completion.html
  # signature = ${if account?signatureFilename or ""}
  # gpg_key = ${account.gpgKey}  D7D6C5AA
  # 
  # gpg_key ID 
  accountStr = {name, userName, address, realname, ...} @ account:
    ''
      [[${name}]]
      address=${address}
      realname=${realname}
      sendmail_command = ${account.mta.sendCommand account}
      signature_as_attachment = ${if account.showSignature == "attach" then "True" else "False"}

      # contact completion
      ${contactCompletionStr account} 
      ${if account.showSignature == "attach" then "gpg_key = {account." else ""}
        
    ''
    ;

# alot hooks use default for now
# hooksfile = ${xdg.configFile."alot/hm_hooks"}
configFile = let
  extraConfigStr = entries: concatStringsSep "\n" (
    mapAttrsToList (key: val: "${key} = ${val}") entries
  );
in
      mailAccounts: pkgs.writeText "alot.conf" (''

    theme = ${cfg.theme}
    ${extraConfigStr cfg.extraConfig}

    [bindings] 
    ${cfg.bindings}

    # TODO we should prepare our own hooks file
    # hooksfile
    [accounts]

    ${concatStringsSep "\n" (map accountStr mailAccounts)}

  '');

in
{

  options = {
    programs.alot = {
      enable = mkEnableOption "Alot";

      createAliases = mkOption {
        type = types.bool;
        default = false;
        description = "create alias alot_\${account.name}";
      };

      theme = mkOption {
        type = types.enum [ "solarized_dark" ];
        default = "solarized_dark";
        description = "default theme";
      };

      generateShellAliases = mkOption {
        default = generateNotmuchAlias;
        description = "default theme";
      };

      contactCompletionCommand = mkOption {
        default = contactCompletionStr;
        description = "Can override what is decided in contactCompletion";
      };

      bindings = mkOption {
        # type = types.submoduleOf
        # type = types.attrs;
        # default = {
        #   # TODO it should
    # # % = "shellescape ${account.mra.fetchMailCommand account} ; refresh"
        #    "%" = "refresh";
        # };
        type = types.lines;
        default = ''
          % = refresh;
        '';
        description = "Can override what is decided in contactCompletion";
      };

      # what about editor/editor_spawn
      extraConfig = mkOption {
        type = types.attrs;
        default = {
          auto_remove_unread = "True";
          ask_subject = "False";
          handle_mouse = "True";
          # launch sequence of commands separated by ;;
          initial_command = "search tag:inbox AND NOT tag:killed";
          input_timeout=0.3;
          prefer_plaintext = "True";
          thread_indent_replies = 4;
        };
        description = "Extra configuration lines to add to ~/.config/alot/config.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.alot ];

      # programs.zsh.shellAliases = lib.optional cfg.createAliases 
      # # (map {} )
      # (zipAttrsWith (account: )  home.mail.accounts)
      # ;

      # ca s appelle notmuchrc plutot
    xdg.configFile."alot/config".source = configFile config.mail.accounts;
    # xdg.configFile = (map (account: {
    #   target = "alot/alot-${account.name}";
    #   text = configFile account; 
    # }) top.config.mail.accounts)
    # ++ [
    #   { target = "alot/hm_hooks";
    #     text = ''
    #     # Home-manager custom hooks
    #     '';
    #   } ]

      xdg.configFile."alot/hm_hooks".text = ''
        # Home-manager custom hooks
        '';
  };
}

