{ lib, options, ... }:
{
  accounts.email = {
    maildirBasePath = "Mail";

    accounts = {
      "hm@example.com" = {
        primary = true;
        address = "hm@example.com";
        userName = "home.manager";
        realName = "H. M. Test";
        passwordCommand = "password-command";
        imap.host = "imap.example.com";
        smtp.host = "smtp.example.com";
      };

      hm-account = {
        address = "hm@example.org";
        userName = "home.manager.jr";
        realName = "H. M. Test Jr.";
        passwordCommand = "password-command 2";
        imap.host = "imap.example.org";
        smtp.host = "smtp.example.org";
        smtp.tls.useStartTls = true;
      };

      # Account that throws an error if any interesting account attribute is
      # accessed other than the `enable` attribute.  This is a bit awkward as
      # we can't throw just for accessing some submodules, as some get accessed
      # just as part of merging config, but it ensures a disabled account is
      # genuinely disabled.
      disabled-account =
        let
          # This is intended for use in generating documentation, but it's
          # useful here as a way to get a list of attributes that might be
          # defined.
          accountAttrOptions = options.accounts.email.accounts.type.nestedTypes.elemType.getSubOptions [ ];

          throwOnAttrAccess =
            baseName: builtins.mapAttrs (n: v: throw "Unexpected access of ${baseName}.${n}");

          # Don't want to do anything with these account attributes.
          ignoredAttrNames = [
            "_module"
            "enable"
          ];

          # These are submodules, which means the config attribute will be
          # accessed even if subattributes aren't.  This means we can't throw
          # an error as soon as one of these is accessed, and instead need to
          # throw errors if an attribute of this submodule is accessed.
          submoduleAttrNames = [
            "aerc"
            "alot"
            "astroid"
            "getmail"
            "himalaya"
            "imapnotify"
            "lieer"
            "mbsync"
            "meli"
            "msmtp"
            "mu"
            "mujmap"
            "neomutt"
            "notmuch"
            "offlineimap"
            "thunderbird"
          ];

          # Other attributes should never be accessed if the account is
          # disabled, so throw an error if they are.
          baseAttrThrows = throwOnAttrAccess "accounts.email.accounts.disabled-account" (
            removeAttrs accountAttrOptions (ignoredAttrNames ++ submoduleAttrNames)
          );

          submoduleToAttrThrows =
            name:
            let
              submoduleAttrOptions = builtins.getAttr name accountAttrOptions;

              # Some submodules have sub-submodules, and they need the same
              # special handling.
              #
              # Ideally this would be some recursive function to avoid
              # repeating the code, potentially using introspection to workout
              # which options are submodules, but that's complicated and
              # unnecessary for now.
              subSubmoduleAttrNames =
                if name == "lieer" then
                  [ "sync" ]
                else if name == "mbsync" then
                  [ "extraConfig" ]
                else if name == "msmtp" then
                  [ "tls" ]
                else if name == "notmuch" then
                  [ "neomutt" ]
                else if name == "offlineimap" then
                  [ "extraConfig" ]
                else
                  [ ];
              subSubmoduleThrows = lib.genAttrs subSubmoduleAttrNames (
                n:
                throwOnAttrAccess "accounts.email.accounts.disabled-account.${name}.${n}" (
                  builtins.getAttr n submoduleAttrOptions
                )
              );
              baseThrows = throwOnAttrAccess "accounts.email.accounts.disabled-account.${name}" (
                removeAttrs submoduleAttrOptions subSubmoduleAttrNames
              );
            in
            baseThrows // subSubmoduleThrows;

          submoduleAttrThrows = lib.genAttrs submoduleAttrNames submoduleToAttrThrows;
        in
        lib.mergeAttrsList [
          baseAttrThrows
          submoduleAttrThrows
          { enable = false; }
        ];
    };
  };
}
