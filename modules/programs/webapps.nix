{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.webApps;

  # Type for a single web app
  webAppOpts = types.submodule ({
    options = {
      url = mkOption {
        type = types.str;
        description = "URL of the web application to launch.";
        example = "https://github.com";
      };

      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of the web application. If not provided, will be derived from the attribute name.";
        example = "GitHub";
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
        type = with types; nullOr (listOf str);
        default = [
          "Network"
          "WebBrowser"
        ];
        description = "Categories in which the entry should be shown in application menus.";
        example = ''[ "Development" "Network" ]'';
      };

      mimeTypes = mkOption {
        type = with types; nullOr (listOf str);
        default = null;
        description = "The MIME types supported by this application.";
        example = ''[ "x-scheme-handler/mailto" ]'';
      };

      startupWmClass = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The StartupWMClass to use in the .desktop file.";
        example = "github.com";
      };

      extraOptions = mkOption {
        type = types.attrs;
        default = { };
        description = "Extra options to pass to the browser when launching the webapp.";
        example = ''{ profile-directory = "Profile 3"; }'';
      };
    };
  });

  # Get browser command based on package
  getBrowserCommand =
    browserPkg: url: extraOptions:
    let
      # Desktop entries don't need shell escaping, just basic space escaping
      escapeDesktopArg = arg: builtins.replaceStrings [ " " ] [ "\\ " ] (toString arg);

      optionString = concatStringsSep " " (
        mapAttrsToList (name: value: "--${name}=${escapeDesktopArg value}") extraOptions
      );

      # Detect browser type from package name
      browserName = browserPkg.pname or (builtins.parseDrvName browserPkg.name).name;

      isChromiumBased = elem browserName [
        "chromium"
        "brave"
        "google-chrome"
        "google-chrome-stable"
        "vivaldi"
      ];

      binary = "${toString browserPkg}/bin/${browserName}";
    in
    if isChromiumBased then
      "${binary} --app=${escapeDesktopArg url} ${optionString}"
    else if browserName == "firefox" then
      "${binary} ${escapeDesktopArg url}" # Firefox doesn't support --app mode
    else
      # Fallback: assume chromium-based behavior
      "${binary} --app=${escapeDesktopArg url} ${optionString}";

  # Auto-detect browser if not explicitly set
  detectedBrowser =
    if cfg.browser != null then
      cfg.browser
    else if config.programs.chromium.enable && config.programs.chromium.package != null then
      config.programs.chromium.package
    else if config.programs.brave.enable && config.programs.brave.package != null then
      config.programs.brave.package
    else if config.programs.firefox.enable && config.programs.firefox.package != null then
      config.programs.firefox.package
    else
      pkgs.chromium; # Default fallback

  # Create a desktop entry for a webapp
  makeWebAppDesktopEntry =
    name: appCfg:
    let
      # Derive app name if not explicitly set
      appName = if appCfg.name != null then appCfg.name else name;

      # Get the browser package
      browserPkg = detectedBrowser;

      # Create the launch command
      launchCommand = getBrowserCommand browserPkg appCfg.url appCfg.extraOptions;

      # Get browser name for StartupWMClass
      browserName = browserPkg.pname or (builtins.parseDrvName browserPkg.name).name;

      # Prepare StartupWMClass
      startupWmClass =
        if appCfg.startupWmClass != null then appCfg.startupWmClass else "${browserName}-webapp-${name}";
    in
    nameValuePair "webapp-${name}" {
      name = appName;
      genericName = "${appName} Web App";
      exec = launchCommand;
      icon = appCfg.icon;
      terminal = false;
      type = "Application";
      categories = appCfg.categories;
      mimeType = appCfg.mimeTypes;
      settings = {
        StartupWMClass = startupWmClass;
      };
    };

in
{
  meta.maintainers = with lib.maintainers; [ realsnick ];

  options.programs.webApps = {
    enable = mkEnableOption "web applications";

    browser = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.chromium";
      description = ''
        Browser package to use for launching web applications.
        If null, will try to auto-detect from enabled browser programs.
        Chromium-based browsers (chromium, brave, google-chrome) work best with --app mode.
      '';
    };

    apps = mkOption {
      type = types.attrsOf webAppOpts;
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
    assertions = [
      {
        assertion = cfg.browser == null || lib.isDerivation cfg.browser;
        message = ''
          programs.webApps: browser must be a package derivation or null for auto-detection.
        '';
      }
    ];

    # Create desktop entries for each web app
    xdg.desktopEntries = mapAttrs' makeWebAppDesktopEntry cfg.apps;
  };
}
