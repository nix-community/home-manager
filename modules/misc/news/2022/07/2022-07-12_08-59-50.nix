{ config, ... }:

{
  time = "2022-07-12T08:59:50+00:00";
  condition = config.services.picom.enable;
  message = ''

    The 'services.picom' module has been refactored to use structural
    settings.

    As a result 'services.picom.extraOptions' has been removed in favor of
    'services.picom.settings'. Also, 'services.picom.blur*' were removed
    since upstream changed the blur settings to be more flexible. You can
    migrate the blur settings to use 'services.picom.settings' instead.
  '';
}
