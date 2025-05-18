{
  config,
  lib,
  pkgs,
  appName,
  package,
  modulePath,
  profilePath,
}:
let
  inherit (lib)
    mapAttrs
    mapAttrs'
    mkOption
    optionalAttrs
    types
    warn
    ;

  jsonFormat = pkgs.formats.json { };

  # Map of nice field names to internal field names.
  # This is intended to be exhaustive and should be
  # updated at every version bump.
  internalFieldNames =
    (lib.genAttrs [
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
    ] (name: "_${name}"))
    // {
      searchForm = "__searchForm";
    };

  # Convenience to specify absolute path to icon
  iconUrl = icon: if lib.isPath icon || lib.hasPrefix "/" icon then "file://${icon}" else icon;

  processCustomEngineInput =
    input:
    {
      name = input.id;
    }
    // (removeAttrs input [ "icon" ])
    // optionalAttrs (input ? icon || input ? iconMapObj) {
      iconMapObj = mapAttrs (name: iconUrl) (
        (optionalAttrs (input ? icon) {
          # Convenience to specify single icon instead of map
          "16" = input.icon;
        })
        // (input.iconMapObj or { })
      );
    }
    // {
      # Required for custom engine configurations, loadPaths
      # are unique identifiers that are generally formatted
      # like: [source]/path/to/engine.xml
      loadPath = "[home-manager]/${
        lib.showAttrPath (
          modulePath
          ++ [
            "engines"
            input.id
          ]
        )
      }";
    };

  processEngineInput =
    id: input:
    let
      requiredInput = {
        inherit id;
        isAppProvided = input.isAppProvided or (removeAttrs input [ "metaData" ] == { });
        metaData = input.metaData or { };
      };
    in
    if requiredInput.isAppProvided then
      requiredInput
    else
      lib.pipe (input // requiredInput) [
        migrateEngineToV11
        migrateEngineToV12
        processCustomEngineInput
      ];

  buildEngineConfig =
    name: input:
    mapAttrs' (name: value: {
      name = internalFieldNames.${name} or name;
      inherit value;
    }) (processEngineInput name input);

  sortEngineConfigs =
    configs:
    let
      buildEngineConfigWithOrder =
        order: id:
        let
          config =
            configs.${id} or {
              inherit id;
              _isAppProvided = true;
              _metaData = { };
            };
        in
        config
        // {
          _metaData = config._metaData // {
            inherit order;
          };
        };

      engineConfigsWithoutOrder = lib.attrValues (removeAttrs configs config.order);

      sortedEngineConfigs =
        (lib.imap buildEngineConfigWithOrder config.order) ++ engineConfigsWithoutOrder;
    in
    sortedEngineConfigs;

  engineInput =
    config.engines
    // {
      # Infer config.default as an app provided
      # engine if it's not in config.engines
      ${config.default} = config.engines.${config.default} or { };
    }
    // {
      ${config.privateDefault} = config.engines.${config.privateDefault} or { };
    };

  settings = {
    version = 12;
    engines = sortEngineConfigs (mapAttrs buildEngineConfig engineInput);

    metaData =
      optionalAttrs (config.default != null) {
        defaultEngineId = config.default;
        defaultEngineIdHash = "@hash@";
      }
      // optionalAttrs (config.privateDefault != null) {
        privateDefaultEngineId = config.privateDefault;
        privateDefaultEngineIdHash = "@privateHash@";
      }
      // {
        useSavedOrder = config.order != [ ];
      };
  };

  # Home Manager doesn't circumvent user consent and isn't acting
  # maliciously. We're modifying the search outside of the browser, but
  # a claim by Mozilla to remove this would be very anti-user, and
  # is unlikely to be an issue for our use case.
  disclaimer =
    "By modifying this file, I agree that I am doing so "
    + "only within @appName@ itself, using official, user-driven search "
    + "engine selection processes, and in a way which does not circumvent "
    + "user consent. I acknowledge that any attempt to change this file "
    + "from outside of @appName@ is a malicious act, and will be responded "
    + "to accordingly.";

  salt = if config.default != null then profilePath + config.default + disclaimer else null;

  privateSalt =
    if config.privateDefault != null then profilePath + config.privateDefault + disclaimer else null;

  appNameVariable =
    if package == null then
      "appName=${lib.escapeShellArg appName}"
    else
      ''
        applicationIni="$(find ${lib.escapeShellArg package} -maxdepth 3 -path ${lib.escapeShellArg package}'/lib/*/application.ini' -print -quit)"
        if test -n "$applicationIni"; then
          appName="$(sed -n 's/^Name=\(.*\)$/\1/p' "$applicationIni" | head -n1)"
        else
          appName=${lib.escapeShellArg appName}
        fi
      '';

  file =
    pkgs.runCommand "search.json.mozlz4"
      {
        nativeBuildInputs = with pkgs; [
          mozlz4a
          openssl
        ];
        json = builtins.toJSON settings;
        inherit salt privateSalt;
      }
      ''
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

  engineNameToId = {
    # Derived from https://searchfox.org/mozilla-central/rev/e3f42ec9320748b2aab3d474d1e47075def9000c/services/settings/dumps/main/search-config-v2.json
    "1&1 Suche" = "1und1";
    "Allegro" = "allegro-pl";
    "Amazon.co.jp" = "amazon-jp";
    "Amazon.com" = "amazondotcom-us";
    "Azerdict" = "azerdict";
    "百度" = "baidu";
    "Bing" = "bing";
    "Ordbok" = "bok-NO";
    "Ceneje.si" = "ceneji";
    "Cốc Cốc" = "coccoc";
    "다음" = "daum-kr";
    "DuckDuckGo" = "ddg";
    "eBay" = "ebay";
    "Ecosia" = "ecosia";
    "EUdict Eng->Cro" = "eudict";
    "Am Faclair Beag" = "faclair-beag";
    "GMX Suche" = "gmx-de";
    "GMX Search" = "gmx-en-GB";
    "GMX - Búsqueda web" = "gmx-es";
    "GMX - Recherche web" = "gmx-fr";
    "GMX Shopping" = "gmx-shopping";
    "Google" = "google";
    "Gule sider" = "gulesider-NO";
    "LEO Eng-Deu" = "leo_ende_de";
    "พจนานุกรม ลองดู" = "longdo";
    "mail.com search" = "mailcom";
    "Mapy.cz" = "mapy-cz";
    "MercadoLibre Argentina" = "mercadolibre-ar";
    "MercadoLibre Chile" = "mercadolibre-cl";
    "MercadoLibre Mexico" = "mercadolibre-mx";
    "MercadoLivre" = "mercadolivre";
    "네이버" = "naver-kr";
    "Odpiralni Časi" = "odpiralni";
    "Pazaruvaj" = "pazaruvaj";
    "Priberam" = "priberam";
    "Prisjakt" = "prisjakt-sv-SE";
    "Qwant" = "qwant";
    "Qwant Junior" = "qwantjr";
    "楽天市場" = "rakuten";
    "Readmoo 讀墨電子書" = "readmoo";
    "Reddit" = "reddit";
    "Salidzini.lv" = "salidzinilv";
    "Seznam" = "seznam-cz";
    "Tyda.se" = "tyda-sv-SE";
    "Vatera.hu" = "vatera";
    "WEB.DE Suche" = "webde";
    "Wikipedia (en)" = "wikipedia";
    "Wikipedia (nn)" = "wikipedia-NN";
    "Wikipedia (nb)" = "wikipedia-NO";
    "Wikipedia (af)" = "wikipedia-af";
    "Biquipedia (an)" = "wikipedia-an";
    "ويكيبيديا (ar)" = "wikipedia-ar";
    "Wikipedia (ast)" = "wikipedia-ast";
    "Vikipediya (az)" = "wikipedia-az";
    "Вікіпедыя (be)" = "wikipedia-be";
    "Вікіпэдыя (be-tarask)" = "wikipedia-be-tarask";
    "Уикипедия (bg)" = "wikipedia-bg";
    "উইকিপিডিয়া (bn)" = "wikipedia-bn";
    "Wikipedia (br)" = "wikipedia-br";
    "Wikipedia (bs)" = "wikipedia-bs";
    "Viquipèdia (ca)" = "wikipedia-ca";
    "Wicipedia (cy)" = "wikipedia-cy";
    "Wikipedie (cs)" = "wikipedia-cz";
    "Wikipedia (da)" = "wikipedia-da";
    "Wikipedia (de)" = "wikipedia-de";
    "Wikipedija (dsb)" = "wikipedia-dsb";
    "Βικιπαίδεια (el)" = "wikipedia-el";
    "Vikipedio (eo)" = "wikipedia-eo";
    "Wikipedia (es)" = "wikipedia-es";
    "Vikipeedia (et)" = "wikipedia-et";
    "Wikipedia (eu)" = "wikipedia-eu";
    "ویکی‌پدیا (fa)" = "wikipedia-fa";
    "Wikipedia (fi)" = "wikipedia-fi";
    "Wikipédia (fr)" = "wikipedia-fr";
    "Wikipedy (fy)" = "wikipedia-fy-NL";
    "Vicipéid (ga)" = "wikipedia-ga-IE";
    "Uicipeid (gd)" = "wikipedia-gd";
    "Wikipedia (gl)" = "wikipedia-gl";
    "Vikipetã (gn)" = "wikipedia-gn";
    "વિકિપીડિયા (gu)" = "wikipedia-gu";
    "ויקיפדיה" = "wikipedia-he";
    "विकिपीडिया (hi)" = "wikipedia-hi";
    "Wikipedija (hr)" = "wikipedia-hr";
    "Wikipedija (hsb)" = "wikipedia-hsb";
    "Wikipédia (hu)" = "wikipedia-hu";
    "Վիքիպեդիա (hy)" = "wikipedia-hy";
    "Wikipedia (ia)" = "wikipedia-ia";
    "Wikipedia (id)" = "wikipedia-id";
    "Wikipedia (is)" = "wikipedia-is";
    "Wikipedia (it)" = "wikipedia-it";
    "Wikipedia (ja)" = "wikipedia-ja";
    "ვიკიპედია (ka)" = "wikipedia-ka";
    "Wikipedia (kab)" = "wikipedia-kab";
    "Уикипедия (kk)" = "wikipedia-kk";
    "វិគីភីឌា (km)" = "wikipedia-km";
    "ವಿಕಿಪೀಡಿಯ (kn)" = "wikipedia-kn";
    "위키백과 (ko)" = "wikipedia-kr";
    "Wikipedia (lij)" = "wikipedia-lij";
    "ວິກິພີເດຍ (lo)" = "wikipedia-lo";
    "Vikipedija (lt)" = "wikipedia-lt";
    "Vikipedeja (ltg)" = "wikipedia-ltg";
    "Vikipēdija (lv)" = "wikipedia-lv";
    "Википедија (mk)" = "wikipedia-mk";
    "विकिपीडिया (mr)" = "wikipedia-mr";
    "Wikipedia (ms)" = "wikipedia-ms";
    "ဝီကီပီးဒီးယား (my)" = "wikipedia-my";
    "विकिपिडिया (ne)" = "wikipedia-ne";
    "Wikipedia (nl)" = "wikipedia-nl";
    "Wikipèdia (oc)" = "wikipedia-oc";
    "ਵਿਕੀਪੀਡੀਆ (pa)" = "wikipedia-pa";
    "Wikipedia (pl)" = "wikipedia-pl";
    "Wikipédia (pt)" = "wikipedia-pt";
    "Wikipedia (rm)" = "wikipedia-rm";
    "Wikipedia (ro)" = "wikipedia-ro";
    "Википедия (ru)" = "wikipedia-ru";
    "විකිපීඩියා (si)" = "wikipedia-si";
    "Wikipédia (sk)" = "wikipedia-sk";
    "Wikipedija (sl)" = "wikipedia-sl";
    "Wikipedia (sq)" = "wikipedia-sq";
    "Википедија (sr)" = "wikipedia-sr";
    "Wikipedia (sv)" = "wikipedia-sv-SE";
    "விக்கிப்பீடியா (ta)" = "wikipedia-ta";
    "వికీపీడియా (te)" = "wikipedia-te";
    "วิกิพีเดีย" = "wikipedia-th";
    "Wikipedia (tl)" = "wikipedia-tl";
    "Vikipedi (tr)" = "wikipedia-tr";
    "Вікіпедія (uk)" = "wikipedia-uk";
    "ویکیپیڈیا (ur)" = "wikipedia-ur";
    "Vikipediya (uz)" = "wikipedia-uz";
    "Wikipedia (vi)" = "wikipedia-vi";
    "Wikipedia (wo)" = "wikipedia-wo";
    "维基百科" = "wikipedia-zh-CN";
    "Wikipedia (zh)" = "wikipedia-zh-TW";
    "ವಿಕ್ಷನರಿ (kn)" = "wiktionary-kn";
    "Wikiccionari (oc)" = "wiktionary-oc";
    "விக்சனரி (ta)" = "wiktionary-ta";
    "విక్షనరీ (te)" = "wiktionary-te";
    "Wolne Lektury" = "wolnelektury-pl";
    "Yahoo! JAPAN" = "yahoo-jp";
    "Yahoo!オークション" = "yahoo-jp-auctions";
    "YouTube" = "youtube";

    # Derived from https://searchfox.org/mozilla-central/rev/e3f42ec9320748b2aab3d474d1e47075def9000c/toolkit/components/search/SearchSettings.sys.mjs#32-44
    "Wikipedia (hy)" = "wikipedia-hy";
    "Wikipedia (kn)" = "wikipedia-kn";
    "Vikipēdija" = "wikipedia-lv";
    "Wikipedia (no)" = "wikipedia-NO";
    "Wikipedia (el)" = "wikipedia-el";
    "Wikipedia (lt)" = "wikipedia-lt";
    "Wikipedia (my)" = "wikipedia-my";
    "Wikipedia (pa)" = "wikipedia-pa";
    "Wikipedia (pt)" = "wikipedia-pt";
    "Wikipedia (si)" = "wikipedia-si";
    "Wikipedia (tr)" = "wikipedia-tr";
  };

  migrateEngineNameToIdV7 =
    engine:
    if builtins.hasAttr engine engineNameToId then
      warn
        "Search engines are now referenced by id instead of by name, use '${engineNameToId.${engine}}' instead of '${engine}'"
        engineNameToId.${engine}
    else
      engine;

  migrateEngineToV11 =
    engine:
    engine
    // lib.optionalAttrs (engine ? iconMapObj) {
      iconMapObj = mapAttrs' (
        name: value:
        let
          nameToIntResult = builtins.tryEval (lib.toInt name);
        in
        {
          name =
            if nameToIntResult.success then
              name
            else
              let
                size = toString (builtins.fromJSON name).width;
              in
              warn "JSON object names for 'iconMapObj' are deprecated, use '${size}' instead of '${name}'" size;

          inherit value;
        }
      ) engine.iconMapObj;
    };

  migrateEngineToV12 =
    engine:
    let
      iconMapObj =
        optionalAttrs (engine ? iconURL) {
          "16" =
            warn "'iconURL' is deprecated, use 'icon = ${lib.strings.escapeNixString engine.iconURL}' instead" engine.iconURL;
        }
        // optionalAttrs (engine ? iconUpdateURL) {
          "16" =
            warn "'iconUpdateURL' is deprecated, use 'icon = ${lib.strings.escapeNixString engine.iconUpdateURL}' instead" engine.iconUpdateURL;
        }
        // (engine.iconMapObj or { });
    in
    lib.throwIf (engine ? hasPreferredIcon) "hasPreferredIcon has been removed" (
      removeAttrs engine [
        "iconURL"
        "iconUpdateURL"
      ]
    )
    // lib.optionalAttrs (iconMapObj != { }) { inherit iconMapObj; };
in
{
  imports = [ (pkgs.path + "/nixos/modules/misc/meta.nix") ];

  meta.maintainers = with lib.maintainers; [ kira-bruneau ];

  options = {
    enable = mkOption {
      type = with types; bool;
      default =
        config.default != null
        || config.privateDefault != null
        || config.order != [ ]
        || config.engines != { };
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
      apply = engine: if engine != null then migrateEngineNameToIdV7 engine else null;
      default = null;
      example = "ddg";
      description = ''
        The default search engine used in the address bar and search
        bar.
      '';
    };

    privateDefault = mkOption {
      type = with types; nullOr str;
      apply = engine: if engine != null then migrateEngineNameToIdV7 engine else null;
      default = null;
      example = "ddg";
      description = ''
        The default search engine used in the Private Browsing.
      '';
    };

    order = mkOption {
      type = with types; uniq (listOf str);
      apply = builtins.map migrateEngineNameToIdV7;
      default = [ ];
      example = [
        "ddg"
        "google"
      ];
      description = ''
        The order the search engines are listed in. Any engines that
        aren't included in this list will be listed after these in an
        unspecified order.
      '';
    };

    engines = mkOption {
      type = with types; attrsOf (attrsOf jsonFormat.type);

      apply = mapAttrs' (
        name: value: {
          name = migrateEngineNameToIdV7 name;
          inherit value;
        }
      );

      default = { };
      example = lib.literalExpression ''
        {
          nix-packages = {
            name = "Nix Packages";
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

          nixos-wiki = {
            name = "NixOS Wiki";
            urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
            iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
            definedAliases = [ "@nw" ];
          };

          bing.metaData.hidden = true;
          google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias
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
