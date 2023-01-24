{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.mujmap;

  mujmapAccounts =
    filter (a: a.mujmap.enable) (attrValues config.accounts.email.accounts);

  missingNotmuchAccounts = map (a: a.name)
    (filter (a: !a.notmuch.enable && a.mujmap.notmuchSetupWarning)
      mujmapAccounts);

  notmuchConfigHelp =
    map (name: "accounts.email.accounts.${name}.notmuch.enable = true;")
    missingNotmuchAccounts;

  settingsFormat = pkgs.formats.toml { };

  filterNull = attrs: attrsets.filterAttrs (n: v: v != null) attrs;

  configFile = account:
    let
      settings'' = if (account.jmap == null) then
        { }
      else
        filterNull {
          fqdn = account.jmap.host;
          session_url = account.jmap.sessionUrl;
        };

      settings' = settings'' // {
        username = account.userName;
        password_command = escapeShellArgs account.passwordCommand;
      } // filterNull account.mujmap.settings;

      settings = if (hasAttr "fqdn" settings') then
        (removeAttrs settings' [ "session_url" ])
      else
        settings';
    in {
      name = "${account.maildir.absPath}/mujmap.toml";
      value.source = settingsFormat.generate
        "mujmap-${lib.replaceStrings [ "@" ] [ "_at_" ] account.address}.toml"
        settings;
    };

  tagsOpts = {
    lowercase = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If true, translate all mailboxes to lowercase names when mapping to notmuch
        tags.
      '';
    };

    directory_separator = mkOption {
      type = types.str;
      default = "/";
      example = ".";
      description = ''
        Directory separator for mapping notmuch tags to maildirs.
      '';
    };

    inbox = mkOption {
      type = types.str;
      default = "inbox";
      description = ''
        Tag for notmuch to use for messages stored in the mailbox labeled with the
        <code>Inbox</code> name attribute.
        </para><para>
        If set to an empty string, this mailbox <emphasis>and its child
        mailboxes</emphasis> are not synchronized with a tag.
      '';
    };

    deleted = mkOption {
      type = types.str;
      default = "deleted";
      description = ''
        Tag for notmuch to use for messages stored in the mailbox labeled with the
        <code>Trash</code> name attribute.
        </para><para>
        If set to an empty string, this mailbox <emphasis>and its child
        mailboxes</emphasis> are not synchronized with a tag.
      '';
    };

    sent = mkOption {
      type = types.str;
      default = "sent";
      description = ''
        Tag for notmuch to use for messages stored in the mailbox labeled with the
        <code>Sent</code> name attribute.
        </para><para>
        If set to an empty string, this mailbox <emphasis>and its child
        mailboxes</emphasis> are not synchronized with a tag.
      '';
    };

    spam = mkOption {
      type = types.str;
      default = "spam";
      description = ''
        Tag for notmuch to use for messages stored in the mailbox labeled with the
        <code>Junk</code> name attribute and/or with the <code>$Junk</code> keyword,
        <emphasis>except</emphasis> for messages with the <code>$NotJunk</code> keyword.
        </para><para>
        If set to an empty string, this mailbox, <emphasis>its child
        mailboxes</emphasis>, and these keywords are not synchronized with a tag.
      '';
    };

    important = mkOption {
      type = types.str;
      default = "important";
      description = ''
        Tag for notmuch to use for messages stored in the mailbox labeled with the
        <code>Important</code> name attribute and/or with the <code>$Important</code>
        keyword.
        </para><para>
        If set to an empty string, this mailbox, <emphasis>its child
        mailboxes</emphasis>, and these keywords are not synchronized with a tag.
      '';
    };

    phishing = mkOption {
      type = types.str;
      default = "phishing";
      description = ''
        Tag for notmuch to use for the IANA <code>$Phishing</code> keyword.
        </para><para>
        If set to an empty string, this keyword is not synchronized with a tag.
      '';
    };
  };

  rootOpts = {
    username = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "alice@example.com";
      description = ''
        Username for basic HTTP authentication.
        </para><para>
        If <literal>null</literal>, defaults to
        <xref linkend="opt-accounts.email.accounts._name_.userName"/>.
      '';
    };

    password_command = mkOption {
      type = types.nullOr (types.either types.str (types.listOf types.str));
      default = null;
      apply = p: if isList p then escapeShellArgs p else p;
      example = "pass alice@example.com";
      description = ''
        Shell command which will print a password to stdout for basic HTTP
        authentication.
        </para><para>
        If <literal>null</literal>, defaults to
        <xref linkend="opt-accounts.email.accounts._name_.passwordCommand"/>.
      '';
    };

    fqdn = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "example.com";
      description = ''
        Fully qualified domain name of the JMAP service.
        </para><para>
        mujmap looks up the JMAP SRV record for this host to determine the JMAP session
        URL. Mutually exclusive with
        <xref linkend="opt-accounts.email.accounts._name_.mujmap.settings.session_url"/>.
        </para><para>
        If <literal>null</literal>, defaults to
        <xref linkend="opt-accounts.email.accounts._name_.jmap.host"/>.
      '';
    };

    session_url = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://jmap.example.com/.well-known/jmap";
      description = ''
        Session URL to connect to.
        </para><para>
        Mutually exclusive with
        <xref linkend="opt-accounts.email.accounts._name_.mujmap.settings.fqdn"/>.
        </para><para>
        If <literal>null</literal>, defaults to
        <xref linkend="opt-accounts.email.accounts._name_.jmap.sessionUrl"/>.
      '';
    };

    auto_create_new_mailboxes = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to create new mailboxes automatically on the server from notmuch
        tags.
      '';
    };

    cache_dir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The cache directory in which to store mail files while they are being
        downloaded. The default is operating-system specific.
      '';
    };

    tags = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = tagsOpts;
      };
      default = { };
      description = ''
        Tag configuration.
        </para><para>
        Beware that there are quirks that require manual consideration if changing the
        values of these files; please see
        <link xlink:href="https://github.com/elizagamedev/mujmap/blob/main/mujmap.toml.example"/>
        for more details.
      '';
    };
  };

  mujmapOpts = {
    enable = mkEnableOption "mujmap JMAP synchronization for notmuch";

    notmuchSetupWarning = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Warn if Notmuch is not also enabled for this account.
        </para><para>
        This can safely be disabled if <filename>mujmap.toml</filename> is managed
        outside of Home Manager.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = rootOpts;
      };
      default = { };
      description = ''
        Settings which are applied to <filename>mujmap.toml</filename>
        for the account.
        </para><para>
        See the <link xlink:href="https://github.com/elizagamedev/mujmap">mujmap project</link>
        for documentation of settings not explicitly covered by this module.
      '';
    };
  };

  mujmapModule = types.submodule { options = { mujmap = mujmapOpts; }; };
in {
  meta.maintainers = with maintainers; [ elizagamedev ];

  options = {
    programs.mujmap = {
      enable = mkEnableOption "mujmap Gmail synchronization for notmuch";

      package = mkOption {
        type = types.package;
        default = pkgs.mujmap;
        defaultText = "pkgs.mujmap";
        description = ''
          mujmap package to use.
        '';
      };
    };

    accounts.email.accounts =
      mkOption { type = with types; attrsOf mujmapModule; };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (missingNotmuchAccounts != [ ]) {
      warnings = [''
        mujmap is enabled for the following email accounts, but notmuch is not:

            ${concatStringsSep "\n    " missingNotmuchAccounts}

        Notmuch can be enabled with:

            ${concatStringsSep "\n    " notmuchConfigHelp}

        If you have configured notmuch outside of Home Manager, you can suppress this
        warning with:

            programs.mujmap.notmuchSetupWarning = false;
      ''];
    })

    {
      warnings = flatten (map (account: account.warnings) mujmapAccounts);

      home.packages = [ cfg.package ];

      # Notmuch should ignore non-mail files created by mujmap.
      programs.notmuch.new.ignore = [ "/.*[.](toml|json|lock)$/" ];

      home.file = listToAttrs (map configFile mujmapAccounts);
    }
  ]);
}
