{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  # astroid has no man but astroid --help shows some settings
  cfg = config.programs.astroid;

  generateAlias = account:
  {
    name = "alot-${account.name}";
    value = "${pkgs.astroid}/bin/astroid -c ${config.xdg.configHome}/notmuch/notmuch_${account.name}"; 
  }
 
  astroidConfig = account: "$XDG_CONFIG_HOME/astroid/astroid_${account.name}";

  # toJSON
    # "accounts": {
    #     "charlie": {
    #         "name": "Charlie Root",
    #         "email": "root@localhost",
    #         "gpgkey": "",
    #         "sendmail": "msmtp -t",
    #         "default": "true",
    #         "save_sent": "false",
    #         "save_sent_to": "\/home\/root\/Mail\/sent\/cur\/",
    #         "additional_sent_tags": "",
    #         "save_drafts_to": "\/home\/root\/Mail\/drafts\/",
    #         "signature_file": "",
    #         "signature_default_on": "true",
    #         "signature_attach": "false",
    #         "always_gpg_sign": "false",
    #         "signature_separate": "false",
    #         "select_query": ""
    #     }
    # },
    
  accountStr = {name,userName, address, realname, ...} @ account:
  builtins.toJSON (builtins.removeAttrs account [ "gpgkey" ] // {
            "gpgkey" = account.gpgKey;
            "sendmail" = account.mra.fetchMailCommand account;
            "default": "true",
            "save_sent": "false",
            "save_sent_to": "\/home\/root\/Mail\/sent\/cur\/",
            "additional_sent_tags": "",
            "save_drafts_to": config.mailstore + "/drafts\/",
            "signature_file": "",
            "signature_default_on": "true",
            "signature_attach" = account.showSignature == "attach";
            "always_gpg_sign": "false",
            "signature_separate": "false",
            "select_query": ""
  })
  ;

    bindingStr = ''
      # TODO if offlineimap configured, run offlineimap
      G = call hooks.getmail(ui)
    '';

  # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
  # should we set themes_dir as well ?
# alot hooks use default for now
# hooksfile = ${xdg.configFile."alot/hm_hooks"}
# toJSON

  # TODO load a template


  accountsJson = accounts:
    map ( toJSON account: 
        account.name = {
            name = account.username;
            email = account.address;
            # "gpgkey": "",
            sendmail= account.mta.sendCommand;
            # "default": "true",
            # "save_sent": "false",
            # "save_sent_to": "\/home\/root\/Mail\/sent\/cur\/",
            # "additional_sent_tags": "",
            # "save_drafts_to": "\/home\/root\/Mail\/drafts\/",
            # "signature_file": "",
            # "signature_default_on": "true",
            # "signature_attach": "false",
            # "always_gpg_sign": "false",
            # "signature_separate": "false",
            # "select_query": ""
        }) accounts;


  # load a template with importJSON
  # notmuchConfig = account: "$XDG_CONFIG_HOME/notmuch/notmuch_${account.name}";
  configFile = mailAccounts:
  let
    # TODO recursiveUpdate old/ new
    tpl = builtins.removeAttrs ( builtins.importJSON ./astroid.tpl);

    tpl_updated = recursiveUpdate tpl {
      # astroid.notmuch_config = ;
    };

  in 
  pkgs.writeText "astroid.conf" (
    builtins.toJSON
      {}
    ''

  accounts = {

    ${concatStringsSep "\n" (map accountJson mailAccounts)}

    }
  '' 
  );

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
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/alot/config.";
      };
    };
  };

  config = mkIf cfg.enable {
    # home.packages = [ pkgs.alot ];

      # programs.zsh.shellAliases = lib.optional cfg.createAliases 
      # # (map {} )
      # (zipAttrsWith (account: )  home.mail.accounts)
      # ;

      # ca s appelle notmuchrc plutot
      xdg.configFile."astroid/config".source = configFile config.mail.accounts;

      # xdg.configFile."alot/hm_hooks".text = ''
      #   # Home-manager custom hooks
      #   '';
  };
}

# {
#     "astroid": {
#         "config": {
#             "version": "9"
#         },
#         "notmuch_config": "\/home\/teto\/.config\/notmuch\/notmuchrc",
#         "debug": {
#             "dryrun_sending": "false"
#         },
#         "hints": {
#             "level": "0"
#         }
#     },
#     "thread_index": {
#         "page_jump_rows": "6",
#         "sort_order": "newest",
#         "thread_load_step": "250",
#         "cell": {
#             "font_description": "default",
#             "line_spacing": "2",
#             "date_length": "10",
#             "message_count_length": "4",
#             "authors_length": "20",
#             "subject_color": "#807d74",
#             "subject_color_selected": "#000000",
#             "background_color_selected": "",
#             "tags_length": "80",
#             "tags_upper_color": "#e5e5e5",
#             "tags_lower_color": "#333333",
#             "tags_alpha": "0.5",
#             "hidden_tags": "attachment,flagged,unread",
#             "tags_color": "#31587a"
#         }
#     },
#     "general": {
#         "time": {
#             "clock_format": "local",
#             "same_year": "%b %-e",
#             "diff_year": "%x"
#         }
#     },
#     "editor": {
#         "cmd": "gvim -f -c 'set ft=mail' '+set fileencoding=utf-8' '+set enc=utf-8' '+set ff=unix' %1",
#         "external_editor": "true",
#         "charset": "utf-8",
#         "save_draft_on_force_quit": "true",
#         "attachment_words": "attach",
#         "attachment_directory": "~"
#     },
#     "mail": {
#         "reply": {
#             "quote_line": "Excerpts from %1's message of %2:",
#             "mailinglist_reply_to_sender": "true"
#         },
#         "forward": {
#             "quote_line": "Forwarding %1's message of %2:",
#             "disposition": "inline"
#         },
#         "sent_tags": "sent",
#         "message_id_fqdn": "",
#         "message_id_user": "",
#         "user_agent": "default",
#         "send_delay": "2"
#     },
#     "poll": {
#         "interval": "60"
#     },
#     "attachment": {
#         "external_open_cmd": "xdg-open"
#     },
#     "thread_view": {
#         "open_html_part_external": "true",
#         "open_external_link": "xdg-open",
#         "default_save_directory": "~",
#         "indent_messages": "true",
#         "code_prettify": {
#             "enable": "true",
#             "for_tags": "",
#             "code_tag": "```",
#             "enable_for_patches": "true",
#             "uri_prefix": "https:\/\/google-code-prettify.googlecode.com\/svn\/loader\/"
#         },
#         "gravatar": {
#             "enable": "true"
#         },
#         "mark_unread_delay": "0.5",
#         "expand_flagged": "true",
#         "mathjax": {
#             "enable": "true",
#             "uri_prefix": "https:\/\/cdn.mathjax.org\/mathjax\/latest\/",
#             "for_tags": ""
#         }
#     },
#     "crypto": {
#         "gpg": {
#             "path": "gpg2",
#             "always_trust": "true"
#         }
#     },
#     "saved_searches": {
#         "show_on_startup": "false",
#         "save_history": "true",
#         "history_lines_to_show": "15",
#         "history_lines": "1000"
#     },
#     "accounts": {
#         "charlie": {
#             "name": "Charlie Root",
#             "email": "root@localhost",
#             "gpgkey": "",
#             "sendmail": "msmtp -t",
#             "default": "true",
#             "save_sent": "false",
#             "save_sent_to": "\/home\/root\/Mail\/sent\/cur\/",
#             "additional_sent_tags": "",
#             "save_drafts_to": "\/home\/root\/Mail\/drafts\/",
#             "signature_file": "",
#             "signature_default_on": "true",
#             "signature_attach": "false",
#             "always_gpg_sign": "false",
#             "signature_separate": "false",
#             "select_query": ""
#         }
#     },
#     "startup": {
#         "queries": {
#             "inbox": "tag:inbox"
#         }
#     }
# }

