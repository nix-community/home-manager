{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.astroid;

  jsonFormat = pkgs.formats.json { };

  astroidAccounts = lib.filterAttrs (
    _n: v: v.enable && v.astroid.enable
  ) config.accounts.email.accounts;

  boolOpt = b: if b then "true" else "false";

  accountAttr =
    account:
    with account;
    {
      email = address;
      name = realName;
      sendmail = astroid.sendMailCommand;
      additional_sent_tags = "";
      default = boolOpt primary;
      save_drafts_to = "${maildir.absPath}/${folders.drafts}/cur/";
      save_sent = "true";
      save_sent_to = "${maildir.absPath}/${folders.sent}/cur/";
      select_query = "";
    }
    // lib.optionalAttrs (signature.showSignature != "none") {
      signature_attach = boolOpt (signature.showSignature == "attach");
      signature_default_on = boolOpt (signature.showSignature != "none");
      signature_file = pkgs.writeText "signature.txt" signature.text;
      signature_file_markdown = "false";
      signature_separate = "true"; # prepends '--\n' to the signature
    }
    // lib.optionalAttrs (gpg != null) {
      always_gpg_sign = boolOpt gpg.signByDefault;
      gpgkey = gpg.key;
    }
    // astroid.extraConfig;

in
{
  imports =
    let
      overlay = lib.hm.deprecations.mkSettingsOverlay {
        inherit options;
        from = [
          "programs"
          "astroid"
          "extraConfig"
        ];
        to = [
          "programs"
          "astroid"
          "settings"
        ];
      };
    in
    [
      overlay.module
      (lib.hm.deprecations.mkSettingsChangedOptionModule {
        from = [
          "programs"
          "astroid"
          "externalEditor"
        ];
        to = [
          "programs"
          "astroid"
          "settings"
        ];
        key = "editor";
        priority = 100;
        oldOption = {
          type = types.nullOr types.str;
          default = null;
        };
        convert = cmd: {
          external_editor = "true";
          inherit cmd;
        };
        shadowed = cfg.externalEditor == null;
      })
    ];

  options = {
    programs.astroid = {
      enable = lib.mkEnableOption "Astroid";

      package = lib.mkPackageOption pkgs "astroid" { nullable = true; };

      pollScript = mkOption {
        type = types.str;
        default = "";
        example = "mbsync gmail";
        description = ''
          Script to run to fetch/update mails.
        '';
      };

      settings = mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = {
          poll.interval = "15";
          thread_view.gravatar.enable = "false";
        };
        description = ''
          JSON settings for Astroid. Only configured values are written;
          Astroid supplies its built-in defaults for missing keys. When Astroid
          email accounts are configured, Home Manager adds their account
          settings, the notmuch config path, and the GPG path as per-key
          defaults. When settings are empty, no config file is written.
          Deprecated `extraConfig` forwards into settings with its definition
          priorities. Deprecated `externalEditor` sets `editor.cmd` and
          `editor.external_editor` at ordinary priority (100), so differing
          ordinary definitions of either key conflict with it and a stronger
          definition, such as `lib.mkForce`, wins.

          Apply priorities to individual keys. A `lib.mkForce` on `accounts`
          drops generated account keys, and a weaker priority such as
          `lib.mkDefault` on a section with generated keys is ignored. Use
          `lib.mkForce` to set a generated section to a non-object value.

          Editor command variables: `%1` is the file name, `%2` is the server
          name, and `%3` is the socket ID. See
          <https://github.com/astroidmail/astroid/wiki/Customizing-editor>.
          See <https://github.com/astroidmail/astroid/wiki/Configuration-Reference>
          for available settings.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (import ./accounts.nix));
    };
  };

  config = lib.mkIf cfg.enable {
    # Derivations such as signature files are JSON string values, not objects.
    programs.astroid.settings = lib.mkIf (astroidAccounts != { }) (
      lib.mapAttrsRecursiveCond (value: !lib.isDerivation value) (_: lib.mkOptionDefault) {
        astroid.notmuch_config = "${config.xdg.configHome}/notmuch/default/config";
        accounts = lib.mapAttrs (_n: accountAttr) astroidAccounts;
        crypto.gpg.path = "${pkgs.gnupg}/bin/gpg";
      }
    );

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."astroid/config" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "astroid-config" cfg.settings;
    };

    xdg.configFile."astroid/poll.sh" = lib.mkIf (cfg.pollScript != "") {
      executable = true;
      text = ''
        # Generated by Home Manager

        ${cfg.pollScript}
      '';
    };
  };
}
