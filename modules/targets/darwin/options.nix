{ config, lib, ... }:

with lib;

let
  mkOption = args:
    lib.mkOption (args // {
      type = types.nullOr args.type;
      default = null;
    });

  mkEnableOption = name:
    lib.mkOption {
      type = with types; nullOr bool;
      default = null;
      example = true;
      description = "Whether to enable ${name}.";
    };

  safari = config."com.apple.Safari";
in {
  freeformType = with types; attrsOf attrs;

  options = {
    NSGlobalDomain = {
      AppleLanguages = mkOption {
        type = with types; listOf str;
        example = [ "en" ];
        description = "Sets the language to use in the preferred order.";
      };

      AppleLocale = mkOption {
        type = types.str;
        example = "en_US";
        description = "Configures the user locale.";
      };

      AppleMeasurementUnits = mkOption {
        type = types.enum [ "Centimeters" "Inches" ];
        example = "Centimeters";
        description = "Sets the measurement unit.";
      };

      AppleTemperatureUnit = mkOption {
        type = types.enum [ "Celsius" "Fahrenheit" ];
        example = "Celsius";
        description = "Sets the temperature unit.";
      };

      AppleMetricUnits = mkEnableOption "the metric system";

      NSAutomaticCapitalizationEnabled =
        mkEnableOption "automatic captilization";

      NSAutomaticDashSubstitutionEnabled = mkEnableOption "smart dashes";

      NSAutomaticPeriodSubstitutionEnabled =
        mkEnableOption "period with double space";

      NSAutomaticQuoteSubstitutionEnabled = mkEnableOption "smart quotes";

      NSAutomaticSpellingCorrectionEnabled =
        mkEnableOption "spelling correction";
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = mkOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of <filename>.DS_Store</filename> files on network shares.
          See <link xlink:href="https://support.apple.com/en-us/HT208209">the
          official article</link> for more info.
        '';
      };
      DSDontWriteUSBStores = mkOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of <filename>.DS_Store</filename> files on thumb drives.
        '';
      };
    };

    "com.apple.dock" = {
      tilesize = mkOption {
        type = types.int;
        example = 64;
        description = "Sets the size of the dock.";
      };
      size-immutable = mkEnableOption "locking of the dock size";
      expose-group-apps =
        mkEnableOption "grouping of windows by application in Mission Control";
    };

    "com.apple.menuextra.battery".ShowPercent = mkOption {
      type = types.enum [ "YES" "NO" ];
      example = "NO";
      description = "Whether to show battery percentage in the menu bar.";
    };

    "com.apple.Safari" = {
      AutoOpenSafeDownloads = mkEnableOption "opening of downloaded files";
      AutoFillPasswords = mkEnableOption "autofill of usernames and passwords";
      AutoFillCreditCardData = mkEnableOption "autofill of credit card numbers";
      IncludeDevelopMenu = mkEnableOption ''"Develop" menu in the menu bar'';
      ShowOverlayStatusBar = mkEnableOption "status bar";

      WebKitDeveloperExtrasEnabledPreferenceKey = mkOption {
        type = types.bool;
        description = ''
          Configures the web inspector.

          <warning>
            <para>
              Instead of setting this option directly, set
              <option>IncludeDevelopMenu</option> instead.
            </para>
          </warning>
        '';
      };
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
        mkOption {
          type = types.bool;
          description = ''
            Configures the web inspector.

            <warning>
              <para>
                Instead of setting this option directly, set
                <option>IncludeDevelopMenu</option> instead.
              </para>
            </warning>
          '';
        };
    };

    "com.googlecode.iterm2" = {
      AddNewTabAtEndOfTabs =
        mkEnableOption "placement of new tabs at the end of the tab bar";

      AlternateMouseScroll =
        mkEnableOption "arrow keys when scrolling in alternate screen mode";

      CopySelection = mkEnableOption "copy to clipboard upon selecting text";

      OpenTmuxWindowsIn = mkOption {
        type = types.int;
        example = 2;
        description = ''
          Configures how to restore tmux windows when attaching to a session.

          <variablelist><title>Possible Values</title>
            <varlistentry>
              <term><literal>0</literal></term>
              <listitem><para>Native windows</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>1</literal></term>
              <listitem><para>Native tabs in a new window</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>2</literal></term>
              <listitem><para>Tabs in the attaching window</para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      ExperimentalKeyHandling =
        mkEnableOption "experimental key handling for AquaSKK compatibility";
    };
  };

  config = {
    "com.apple.Safari" = mkIf (safari.IncludeDevelopMenu == true) {
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
        true;
    };
  };
}
