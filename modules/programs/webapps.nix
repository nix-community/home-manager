{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    hasAttr
    literalExpression
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;

  cfg = config.programs.webApps;

  # Browser configurations for known browsers
  browserConfigs = {
    chromium = {
      isChromiumBased = true;
      appFlag = true;
    };
    brave = {
      isChromiumBased = true;
      appFlag = true;
    };
    google-chrome = {
      isChromiumBased = true;
      appFlag = true;
    };
    google-chrome-stable = {
      isChromiumBased = true;
      appFlag = true;
    };
    vivaldi = {
      isChromiumBased = true;
      appFlag = true;
    };
    firefox = {
      isChromiumBased = false;
      appFlag = false;
    };
  };

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

      browserConfig =
        if hasAttr browserName browserConfigs then
          browserConfigs.${browserName}
        else
          # Fallback: assume chromium-based behavior
          {
            isChromiumBased = true;
            appFlag = true;
          };

      binary = "${toString browserPkg}/bin/${browserName}";
    in
    if browserConfig.isChromiumBased then
      "${binary} --app=${escapeDesktopArg url} ${optionString}"
    else
      "${binary} ${escapeDesktopArg url}"; # Firefox doesn't support --app mode

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
      # Get the browser package
      browserPkg = cfg.browser;

      # Create the launch command
      launchCommand = getBrowserCommand browserPkg appCfg.url appCfg.extraOptions;

      # Get browser name for StartupWMClass
      browserName = browserPkg.pname or (builtins.parseDrvName browserPkg.name).name;

      # Prepare StartupWMClass
      startupWmClass =
        if appCfg.startupWmClass != null then appCfg.startupWmClass else "${browserName}-webapp-${name}";
    in
    nameValuePair "webapp-${name}" {
      name = appCfg.name;
      genericName = "${appCfg.name} Web App";
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
  meta.maintainers = with lib.maintainers; [ logger ];

  options.programs.webApps = {
    enable = mkEnableOption "web applications";

    browser = mkOption {
      type = types.package;
      default = detectedBrowser;
      defaultText = literalExpression "pkgs.firefox";
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
                example = ''[ "Development" "Network" ]'';
              };

              mimeTypes = mkOption {
                type = types.nullOr (types.listOf types.str);
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
                type = types.attrsOf (
                  types.oneOf [
                    types.str
                    types.int
                    types.bool
                  ]
                );
                default = { };
                description = "Extra options to pass to the browser when launching the webapp.";
                example = ''{ profile-directory = "Profile 3"; }'';
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
