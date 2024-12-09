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

      ApplePressAndHoldEnabled = mkNullableOption {
        type = types.bool;
        example = true;
        description =
          "Repeat a key when it is held down (false) or display the accented character selector (true)";
      };

      AppleShowAllExtensions = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Always show file extensions in Finder";
      };

      AppleTemperatureUnit = mkNullableOption {
        type = types.enum [ "Celsius" "Fahrenheit" ];
        example = "Celsius";
        description = "Sets the temperature unit.";
      };

      AppleMetricUnits = mkNullableEnableOption "the metric system";

      KeyRepeat = mkNullableOption {
        type = types.int;
        example = 2;
        description = ''
          Interval between key repetitions when holding down a key. Lower is
          faster. When setting through the control panel, 2 is the lowest value,
          and 120 the highest.
        '';
      };

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
      autohide = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Hide the Dock automatically";
      };
      expose-group-apps = mkNullableEnableOption
        "grouping of windows by application in Mission Control";
      orientation = mkNullableOption {
        type = types.enum [ "left" "bottom" "right" ];
        example = "left";
        description = "Position of the Dock on the screen";
      };
      size-immutable = mkNullableEnableOption "locking of the dock size";
      tilesize = mkNullableOption {
        type = types.int;
        example = 64;
        description = "Sets the size of the dock.";
      };
    };

    "com.apple.finder" = {
      AppleShowAllFiles = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Show hidden files in Finder";
      };

      FXRemoveOldTrashItems = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Automatically delete items from trash after 30 days";
      };

      ShowPathBar = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Show the path bar at the bottom of a Finder window";
      };

      ShowStatusBar = mkNullableOption {
        type = types.bool;
        example = true;
        description = "Show the status bar at the bottom of a Finder window";
      };
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

    "com.apple.menuextra.clock" = {
      IsAnalog = mkNullableEnableOption
        "showing an analog clock instead of a digital one";

      Show24Hour = mkNullableEnableOption
        "showing a 24-hour clock, instead of a 12-hour clock";

      ShowAMPM = mkNullableOption {
        type = types.bool;
        description = ''
          Show the AM/PM label. Useful if Show24Hour is false. Default is null.
        '';
      };

      ShowDate = mkNullableOption {
        type = types.enum [ 0 1 2 ];
        description = ''
          Show the full date. Default is null.

          0 = Show the date
          1 = Don't show
          2 = Don't show

          TODO: I don't know what the difference is between 1 and 2.
        '';
      };

      ShowDayOfMonth = mkNullableEnableOption "showing the day of the month";

      ShowDayOfWeek = mkNullableEnableOption "showing the day of the week";

      ShowSeconds = mkNullableEnableOption
        "showing the clock with second precision, instead of minutes";
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
