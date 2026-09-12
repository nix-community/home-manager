{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    literalExpression
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;

  cfg = config.programs.webapps;

  # Browsers that support Chromium's --app=URL standalone-window mode, keyed by
  # executable name (meta.mainProgram). Any browser not listed opens the URL in
  # a normal window, which works everywhere; passing --app to a non-Chromium
  # browser would produce a broken launcher.
  chromiumBasedBrowsers = [
    "chromium"
    "brave"
    "google-chrome"
    "google-chrome-stable"
    "vivaldi"
  ];

  # Get browser command based on package
  getBrowserCommand =
    browserPkg: url: extraOptions:
    let
      # Quote a single token for a freedesktop Exec= field. Per the Desktop
      # Entry spec, a literal "%" must be written as "%%", and any reserved
      # character (whitespace, quotes, and ``"$&;<>?|~*#()``) must sit inside
      # double quotes, within which `\`, `"`, `` ` `` and `$` are
      # backslash-escaped. desktop-file-validate (run in makeDesktopItem's
      # checkPhase) rejects unquoted reserved characters, so without this a
      # perfectly ordinary URL containing "?" or "&" would fail the build.
      quoteExecArg =
        arg:
        let
          s = builtins.replaceStrings [ "%" ] [ "%%" ] (toString arg);
          reserved = [
            " "
            "\t"
            "\n"
            "\""
            "'"
            "\\"
            "`"
            "$"
            "&"
            ";"
            "<"
            ">"
            "|"
            "~"
            "*"
            "?"
            "#"
            "("
            ")"
          ];
          escaped = builtins.replaceStrings [ "\\" "\"" "`" "$" ] [ "\\\\" "\\\"" "\\`" "\\$" ] s;
        in
        if lib.any (c: lib.hasInfix c s) reserved then ''"${escaped}"'' else s;

      # Render extraOptions as browser flags. A boolean becomes a bare switch
      # ("--incognito") when true and is omitted when false; any other value
      # becomes "--name=value".
      renderOption =
        name: value:
        if builtins.isBool value then lib.optional value "--${name}" else [ "--${name}=${toString value}" ];

      optionArgs = builtins.concatLists (mapAttrsToList renderOption extraOptions);

      # Resolve the launch binary from the package's meta.mainProgram, falling
      # back to the pname-derived name, since a browser's executable name often
      # differs from its package name (e.g. ungoogled-chromium ships `chromium`).
      browserName = browserPkg.pname or (builtins.parseDrvName browserPkg.name).name;
      browserExe = browserPkg.meta.mainProgram or browserName;

      binary = lib.getExe' browserPkg browserExe;

      # Chromium-based browsers open a dedicated app window via --app=URL; any
      # other browser just opens the URL in a normal window.
      isChromiumBased = builtins.elem browserExe chromiumBasedBrowsers;
      urlArg = if isChromiumBased then "--app=${toString url}" else toString url;
    in
    concatStringsSep " " ([ binary ] ++ map quoteExecArg ([ urlArg ] ++ optionArgs));

  # Auto-detect browser if not explicitly set
  detectedBrowser =
    if config.programs.chromium.enable && config.programs.chromium.package != null then
      config.programs.chromium.package
    else if config.programs.brave.enable && config.programs.brave.package != null then
      config.programs.brave.package
    else if config.programs.firefox.enable && config.programs.firefox.package != null then
      config.programs.firefox.package
    else
      pkgs.firefox; # Default to Firefox

  # Create a desktop entry for a webapp
  makeWebAppDesktopEntry =
    name: appCfg:
    let
      # Create the launch command
      launchCommand = getBrowserCommand appCfg.browser appCfg.url appCfg.extraOptions;
    in
    nameValuePair "webapp-${name}" {
      inherit (appCfg) name;
      genericName = "${appCfg.name} Web App";
      exec = launchCommand;
      inherit (appCfg) icon;
      terminal = false;
      type = "Application";
      inherit (appCfg) categories;
      mimeType = appCfg.mimeTypes;
      settings = {
        StartupWMClass = appCfg.startupWmClass;
      };
    };

in
{
  meta.maintainers = with lib.maintainers; [ logger ];

  options.programs.webapps = {
    enable = mkEnableOption "web applications";

    browser = mkOption {
      type = types.package;
      default = detectedBrowser;
      defaultText = lib.literalMD ''
        auto-detected from the first enabled browser program
        (`programs.chromium`, `programs.brave`, `programs.firefox`),
        otherwise `pkgs.firefox`
      '';
      example = literalExpression "pkgs.chromium";
      description = ''
        Browser package to use for launching web applications.

        Defaults to Firefox if no browser program is enabled, otherwise auto-detects
        from enabled browser programs in the following order:
        chromium, brave, firefox.

        Chromium-based browsers (chromium, brave, google-chrome, vivaldi) support
        --app mode for better webapp integration.
      '';
    };

    apps = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              url = mkOption {
                type = types.str;
                description = "URL of the web application to launch.";
                example = "https://github.com";
              };

              name = mkOption {
                type = types.str;
                default = name;
                description = "Name of the web application. Defaults to the attribute name.";
                example = "GitHub";
              };

              browser = mkOption {
                type = types.package;
                default = cfg.browser;
                defaultText = literalExpression "config.programs.webapps.browser";
                example = literalExpression "pkgs.firefox";
                description = ''
                  Browser package to use for this web application.
                  Defaults to the top-level `programs.webapps.browser`.
                '';
              };

              icon = mkOption {
                type = types.nullOr (types.either types.str types.path);
                default = null;
                description = ''
                  Icon for the web application.
                  Can be a path to an icon file or a name of an icon from the current theme.

                  For best results, use declarative icon packages like:
                  - `"$${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/Gmail-mail.google.com.svg"`
                  - Theme icon names like `"mail-client"` (requires icon theme in `home.packages`)

                  Popular icon themes: papirus-icon-theme, adwaita-icon-theme, arc-icon-theme
                '';
                example = literalExpression ''
                  "$${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/Gmail-mail.google.com.svg"
                '';
              };

              categories = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = [
                  "Network"
                  "WebBrowser"
                ];
                description = ''
                  Categories in which the entry should be shown in application menus.

                  See the [Desktop Entry Specification](https://specifications.freedesktop.org/menu-spec/latest/category-registry.html)
                  for a list of standard categories.
                '';
                example = literalExpression ''[ "Development" "Network" ]'';
              };

              mimeTypes = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = null;
                description = "The MIME types supported by this application.";
                example = literalExpression ''[ "x-scheme-handler/mailto" ]'';
              };

              startupWmClass = mkOption {
                type = types.str;
                default = "webapp-${name}";
                description = ''
                  The StartupWMClass to use in the .desktop file.
                  Defaults to the desktop entry name, `webapp-<name>`.
                '';
                example = "github.com";
              };

              extraOptions = mkOption {
                type = types.attrsOf (
                  types.oneOf [
                    types.str
                    types.int
                    types.bool
                  ]
                );
                default = { };
                description = "Extra options to pass to the browser when launching the webapp.";
                example = literalExpression ''{ profile-directory = "Profile 3"; }'';
              };
            };
          }
        )
      );
      default = { };
      description = "Set of web applications to install.";
      example = literalExpression ''
        {
          github = {
            url = "https://github.com";
            icon = "github";
            categories = [ "Development" "Network" ];
          };
          gmail = {
            url = "https://mail.google.com";
            name = "Gmail";
            icon = ./icons/gmail.png;
            mimeTypes = [ "x-scheme-handler/mailto" ];
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create desktop entries for each web app
    xdg.desktopEntries = mapAttrs' makeWebAppDesktopEntry cfg.apps;
  };
}
