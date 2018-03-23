{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.alot;

  generateNotmuchAlias = account:
  {
    name = "alot-${account.name}";
    value = "${pkgs.alot}/bin/alot -n ${config.xdg.configHome}/notmuch/notmuch_${account.name}"; 
  };
 
  # TODO test simple
  # command = 'notmuch address --format=json date:1Y..'
  # TODO might need to add the database too
  # or add --config ?
  contactCompletionStr = account: 
    ''
      [[[abook]]]
      type = shellcommand
      command = '' + (
    if account.contactCompletion == "notmuch address" then ''
      '${pkgs.notmuch}/bin/notmuch address --format=json --output=recipients date:1Y.. AND from:my@address.org'
  regexp = '\[?{"name": "(?P<name>.*)", "address": "(?P<email>.+)", "name-addr": ".*"}[,\]]?'
  shellcommand_external_filtering = False
    '' else if account.contactCompletion == "notmuch address simple" then
    "'${pkgs.notmuch}/bin/notmuch address --format=json date:1Y..'"
    else 
      "");




  # TODO add contact completion
  # https://alot.readthedocs.io/en/latest/configuration/contacts_completion.html
  # signature = ${if account?signatureFilename or ""}
  accountStr = {name, userName, address, realname, ...} @ account:
    ''
      [[${name}]]
      address=${address}
      realname=${realname}
      # gpg_key = D7D6C5AA
      # gpg_key
      sendmail_command = ${account.mta.sendCommand account}
      signature_as_attachment = ${if account.showSignature == "attach" then "True" else "False"}

      # contact completion
      ${contactCompletionStr account} 
        
    '';

    # TODO use
    # bindingStr = ''
    #   # TODO if offlineimap configured, run offlineimap
    #   G = call hooks.getmail(ui)
    # '';

# alot hooks use default for now
# hooksfile = ${xdg.configFile."alot/hm_hooks"}
# mailinglists
  configFile = mailAccounts: pkgs.writeText "alot.conf" (''

    theme = ${cfg.theme}
    ${cfg.extraConfig}
    
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

      generateAliases = mkOption {
        # type = types.enum [ "solarized_dark" ];
        default = generateNotmuchAlias;
        description = "default theme";
      };

      # TODO make it a function of the account
      contactCompletionCommand = mkOption {
        # type = types.str;
        default = contactCompletionStr;
        description = "Can override what is decided in contactCompletion";
      };

      # what about editor/editor_spawn
      # terminal_cmd
      # themes_dir
      extraConfig = mkOption {
        type = types.lines;
        default = ''
          auto_remove_unread = True
          ask_subject = False
          handle_mouse = True
          # launch sequence of commands separated by ;
          initial_command = search tag:inbox AND NOT tag:killed;
          input_timeout=0.3
          prefer_plaintext = True
          thread_indent_replies = 4
        '';
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

      xdg.configFile."alot/hm_hooks".text = ''
        # Home-manager custom hooks
        '';
  };
}

