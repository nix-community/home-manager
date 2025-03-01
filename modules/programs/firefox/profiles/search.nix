{ config, lib, pkgs, appName, package, modulePath, profilePath }:

with lib;

let
  jsonFormat = pkgs.formats.json { };

  # Map of nice field names to internal field names.
  # This is intended to be exhaustive and should be
  # updated at every version bump.
  internalFieldNames = (genAttrs [
    "name"
    "isAppProvided"
    "loadPath"
    "updateInterval"
    "updateURL"
    "iconMapObj"
    "metaData"
    "orderHint"
    "definedAliases"
    "urls"
  ] (name: "_${name}")) // {
    searchForm = "__searchForm";
  };

  # Convenience to specify absolute path to icon
  iconUrl = icon: if hasPrefix "/" icon then "file://${icon}" else icon;

  processCustomEngineInput = input:
    let
      iconMapObj = mapAttrs (name: iconUrl) (optionalAttrs (input ? icon) {
        # Convenience to specify single icon instead of map
        "16" = input.icon;
      } // (input.iconMapObj or { }));
    in (removeAttrs input [ "icon" "iconMapObj" ])
    // optionalAttrs (iconMapObj != { }) { inherit iconMapObj; } // {
      # Required for custom engine configurations, loadPaths
      # are unique identifiers that are generally formatted
      # like: [source]/path/to/engine.xml
      loadPath = "[home-manager]/${
          concatStringsSep "." (map strings.escapeNixIdentifier
            (modulePath ++ [ "engines" input.name ]))
        }";
    };

  processEngineInput = name: input:
    let
      requiredInput = {
        inherit name;
        isAppProvided =
          input.isAppProvided or (removeAttrs input [ "metaData" ] == { });
        metaData = input.metaData or { };
      };
    in if requiredInput.isAppProvided then
      requiredInput
    else
      pipe (input // requiredInput) [
        migrateEngineToV11
        migrateEngineToV12
        processCustomEngineInput
      ];

  buildEngineConfig = name: input:
    mapAttrs' (name: value: {
      name = internalFieldNames.${name} or name;
      inherit value;
    }) (processEngineInput name input);

  sortEngineConfigs = configs:
    let
      buildEngineConfigWithOrder = order: name:
        let
          config = configs.${name} or {
            _name = name;
            _isAppProvided = true;
            _metaData = { };
          };
        in config // { _metaData = config._metaData // { inherit order; }; };

      engineConfigsWithoutOrder = attrValues (removeAttrs configs config.order);

      sortedEngineConfigs = (imap buildEngineConfigWithOrder config.order)
        ++ engineConfigsWithoutOrder;
    in sortedEngineConfigs;

  engineInput = config.engines // {
    # Infer config.default as an app provided
    # engine if it's not in config.engines
    ${config.default} = config.engines.${config.default} or { };
  } // {
    ${config.privateDefault} = config.engines.${config.privateDefault} or { };
  };

  settings = {
    version = 12;
    engines = sortEngineConfigs (mapAttrs buildEngineConfig engineInput);

    metaData = optionalAttrs (config.default != null) {
      current = config.default;
      hash = "@hash@";
    } // optionalAttrs (config.privateDefault != null) {
      private = config.privateDefault;
      privateHash = "@privateHash@";
    } // {
      useSavedOrder = config.order != [ ];
    };
  };

  # Home Manager doesn't circumvent user consent and isn't acting
  # maliciously. We're modifying the search outside of the browser, but
  # a claim by Mozilla to remove this would be very anti-user, and
  # is unlikely to be an issue for our use case.
  disclaimer = "By modifying this file, I agree that I am doing so "
    + "only within @appName@ itself, using official, user-driven search "
    + "engine selection processes, and in a way which does not circumvent "
    + "user consent. I acknowledge that any attempt to change this file "
    + "from outside of @appName@ is a malicious act, and will be responded "
    + "to accordingly.";

  salt = if config.default != null then
    profilePath + config.default + disclaimer
  else
    null;

  privateSalt = if config.privateDefault != null then
    profilePath + config.privateDefault + disclaimer
  else
    null;

  appNameVariable = if package == null then
    "appName=${lib.escapeShellArg appName}"
  else ''
    applicationIni="$(find ${lib.escapeShellArg package} -maxdepth 3 -path ${
      lib.escapeShellArg package
    }'/lib/*/application.ini' -print -quit)"
    if test -n "$applicationIni"; then
      appName="$(sed -n 's/^Name=\(.*\)$/\1/p' "$applicationIni" | head -n1)"
    else
      appName=${lib.escapeShellArg appName}
    fi
  '';

  file = pkgs.runCommand "search.json.mozlz4" {
    nativeBuildInputs = with pkgs; [ mozlz4a openssl ];
    json = builtins.toJSON settings;
    inherit salt privateSalt;
  } ''
    ${appNameVariable}

    salt=''${salt//@appName@/"$appName"}
    privateSalt=''${privateSalt//@appName@/"$appName"}

    if [[ -n $salt ]]; then
      export hash=$(echo -n "$salt" | openssl dgst -sha256 -binary | base64)
      export privateHash=$(echo -n "$privateSalt" | openssl dgst -sha256 -binary | base64)
      mozlz4a <(substituteStream json search.json.in --subst-var hash --subst-var privateHash) "$out"
    else
      mozlz4a <(echo "$json") "$out"
    fi
  '';

  migrateEngineToV11 = engine:
    engine // {
      iconMapObj = mapAttrs' (name: value:
        let nameToIntResult = builtins.tryEval (toInt name);
        in {
          name = if nameToIntResult.success then
            name
          else
            let size = toString (builtins.fromJSON name).width;
            in warn
            "JSON object names for iconMapObj are deprecated, use ${size} instead of ${name}"
            size;

          inherit value;
        }) (engine.iconMapObj or { });
    };

  migrateEngineToV12 = engine:
    throwIf (engine ? hasPreferredIcon) "hasPreferredIcon has been removed"
    (removeAttrs engine [ "iconURL" "iconUpdateURL" ]) // {
      iconMapObj = optionalAttrs (engine ? iconURL) {
        "16" = warn "iconURL is deprecated, use icon = ${
            strings.escapeNixString engine.iconURL
          } instead" engine.iconURL;
      } // optionalAttrs (engine ? iconUpdateURL) {
        "16" = warn "iconUpdateURL is deprecated, use icon = ${
            strings.escapeNixString engine.iconUpdateURL
          } instead" engine.iconUpdateURL;
      } // (engine.iconMapObj or { });
    };
in {
  imports = [ (pkgs.path + "/nixos/modules/misc/meta.nix") ];

  meta.maintainers = with maintainers; [ kira-bruneau ];

  options = {
    enable = mkOption {
      type = with types; bool;
      default = config.default != null || config.privateDefault != null
        || config.order != [ ] || config.engines != { };
      internal = true;
    };

    force = mkOption {
      type = with types; bool;
      default = false;
      description = ''
        Whether to force replace the existing search
        configuration. This is recommended since ${appName} will
        replace the symlink for the search configuration on every
        launch, but note that you'll lose any existing configuration
        by enabling this.
      '';
    };

    default = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "DuckDuckGo";
      description = ''
        The default search engine used in the address bar and search
        bar.
      '';
    };

    privateDefault = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "DuckDuckGo";
      description = ''
        The default search engine used in the Private Browsing.
      '';
    };

    order = mkOption {
      type = with types; uniq (listOf str);
      default = [ ];
      example = [ "DuckDuckGo" "Google" ];
      description = ''
        The order the search engines are listed in. Any engines that
        aren't included in this list will be listed after these in an
        unspecified order.
      '';
    };

    engines = mkOption {
      type = with types; attrsOf (attrsOf jsonFormat.type);
      default = { };
      example = literalExpression ''
        {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS Wiki" = {
            urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
            iconMapObj."16" = "https://wiki.nixos.org/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };

          "Bing".metaData.hidden = true;
          "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
        }
      '';

      description = ''
        Attribute set of search engine configurations. Engines that
        only have {var}`metaData` specified will be treated as builtin
        to ${appName}.

        See [SearchEngine.jsm](https://searchfox.org/mozilla-central/rev/e3f42ec9320748b2aab3d474d1e47075def9000c/toolkit/components/search/SearchEngine.sys.mjs#890-923)
        in ${appName}'s source for available options. We maintain a
        mapping to let you specify all options in the referenced link
        without underscores, but it may fall out of date with future
        options.

        Note, {var}`icon` is also a special option added by Home
        Manager to make it convenient to specify absolute icon paths.
      '';
    };

    file = mkOption {
      type = with types; path;
      default = file;
      internal = true;
      readOnly = true;
      description = ''
        Resulting search.json.mozlz4 file.
      '';
    };
  };
}
