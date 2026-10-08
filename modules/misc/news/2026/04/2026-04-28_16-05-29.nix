{ config, ... }:
{
  time = "2026-04-28T16:05:29+00:00";
  condition = config.programs.thunderbird.enable;
  message = ''
    The `programs.thunderbird.languagePacks` option has been added to install
    and activate Thunderbird language packs.

    The `programs.thunderbird.policies` option has also been added to configure
    Thunderbird enterprise policies. These policies can install Thunderbird
    add-ons through `ExtensionSettings` and configure other supported application
    behavior.

    Thunderbird now supports accounts configured with
    `accounts.email.accounts.<name>.ews`, including the
    `outlook.office365.com-ews` flavor for Office365 Exchange accounts.
  '';
}
