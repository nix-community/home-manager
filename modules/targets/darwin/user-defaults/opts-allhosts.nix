{ config, lib, ... }:

with lib;

let
  mkNullableOption = args:
    lib.mkOption (args // {
      type = types.nullOr args.type;
      default = null;
    });

  mkNullableEnableOption = name:
    lib.mkOption {
      type = with types; nullOr bool;
      default = null;
      example = true;
      description = "Whether to enable ${name}.";
    };

  safari = config."com.apple.Safari";
in {
  freeformType = with types; attrsOf (attrsOf anything);

  options = {
    NSGlobalDomain = {
      AppleLanguages = mkNullableOption {
        type = with types; listOf str;
        example = [ "en" ];
        description = "Sets the language to use in the preferred order.";
      };

      AppleLocale = mkNullableOption {
        type = types.str;
        example = "en_US";
        description = "Configures the user locale.";
      };

      AppleMeasurementUnits = mkNullableOption {
        type = types.enum [ "Centimeters" "Inches" ];
        example = "Centimeters";
        description = "Sets the measurement unit.";
      };

      AppleTemperatureUnit = mkNullableOption {
        type = types.enum [ "Celsius" "Fahrenheit" ];
        example = "Celsius";
        description = "Sets the temperature unit.";
      };

      AppleMetricUnits = mkNullableEnableOption "the metric system";

      NSAutomaticCapitalizationEnabled =
        mkNullableEnableOption "automatic capitalization";

      NSAutomaticDashSubstitutionEnabled =
        mkNullableEnableOption "smart dashes";

      NSAutomaticPeriodSubstitutionEnabled =
        mkNullableEnableOption "period with double space";

      NSAutomaticQuoteSubstitutionEnabled =
        mkNullableEnableOption "smart quotes";

      NSAutomaticSpellingCorrectionEnabled =
        mkNullableEnableOption "spelling correction";
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = mkNullableOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of {file}`.DS_Store` files on network shares.
          See [the
          official article](https://support.apple.com/en-us/HT208209) for more info.
        '';
      };
      DSDontWriteUSBStores = mkNullableOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of {file}`.DS_Store` files on thumb drives.
        '';
      };
    };

    "com.apple.dock" = {
      tilesize = mkNullableOption {
        type = types.int;
        example = 64;
        description = "Sets the size of the dock.";
      };
      size-immutable = mkNullableEnableOption "locking of the dock size";
      expose-group-apps = mkNullableEnableOption
        "grouping of windows by application in Mission Control";
    };

    "com.apple.menuextra.battery".ShowPercent = mkNullableOption {
      type = types.enum [ "YES" "NO" ];
      example = "NO";
      description = ''
        This option no longer works on macOS 11 and later. Instead, use
        {option}`targets.darwin.currentHostDefaults.\"com.apple.controlcenter\".BatteryShowPercentage`.

        Whether to show battery percentage in the menu bar.
      '';
    };

    "com.apple.Safari" = {
      AutoOpenSafeDownloads =
        mkNullableEnableOption "opening of downloaded files";
      AutoFillPasswords =
        mkNullableEnableOption "autofill of usernames and passwords";
      AutoFillCreditCardData =
        mkNullableEnableOption "autofill of credit card numbers";
      IncludeDevelopMenu =
        mkNullableEnableOption ''"Develop" menu in the menu bar'';
      ShowOverlayStatusBar = mkNullableEnableOption "status bar";

      WebKitDeveloperExtrasEnabledPreferenceKey = mkNullableOption {
        type = types.bool;
        description = ''
          Configures the web inspector.

          ::: {.warning}
          Instead of setting this option directly, set
          {option}`IncludeDevelopMenu` instead.
          :::
        '';
      };
      "WebKitPreferences.developerExtrasEnabled" = mkNullableOption {
        type = types.bool;
        description = ''
          Configures the web inspector.

          ::: {.warning}
          Instead of setting this option directly, set
          {option}`IncludeDevelopMenu` instead.
          :::
        '';
      };
    };

    "com.apple.Safari.SandboxBroker" = {
      ShowDevelopMenu = mkNullableOption {
        type = types.bool;
        description = ''
          Show the "Develop" menu in Safari's menubar.

          ::: {.warning}
          Instead of setting this option directly, set
          {option}`"com.apple.Safari".IncludeDevelopMenu` instead.
          :::
        '';
      };
    };

    "com.googlecode.iterm2" = {
      AddNewTabAtEndOfTabs = mkNullableEnableOption
        "placement of new tabs at the end of the tab bar";

      AlternateMouseScroll = mkNullableEnableOption
        "arrow keys when scrolling in alternate screen mode";

      CopySelection =
        mkNullableEnableOption "copy to clipboard upon selecting text";

      OpenTmuxWindowsIn = mkNullableOption {
        type = types.int;
        example = 2;
        description = ''
          Configures how to restore tmux windows when attaching to a session.

          **Possible Values**

          `0`
          : Native windows

          `1`
          : Native tabs in a new window

          `2`
          : Tabs in the attaching window
        '';
      };

      ExperimentalKeyHandling = mkNullableEnableOption
        "experimental key handling for AquaSKK compatibility";
    };
  };

  config = {
    "com.apple.Safari" = mkIf (safari.IncludeDevelopMenu != null) {
      WebKitDeveloperExtrasEnabledPreferenceKey = safari.IncludeDevelopMenu;
      "WebKitPreferences.developerExtrasEnabled" = safari.IncludeDevelopMenu;
    };
    "com.apple.Safari.SandboxBroker" =
      mkIf (safari.IncludeDevelopMenu != null) {
        ShowDevelopMenu = safari.IncludeDevelopMenu;
      };
  };
}
