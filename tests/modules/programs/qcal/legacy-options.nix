{ options, ... }:
{
  programs.qcal = {
    timezone = throw "disabled qcal timezone was evaluated";
    defaultNumDays = throw "disabled qcal defaultNumDays was evaluated";
  };

  assertions = [
    {
      assertion = !options.programs.qcal.timezone.visible;
      message = "The deprecated qcal timezone option should be hidden.";
    }
    {
      assertion = !options.programs.qcal.defaultNumDays.visible;
      message = "The deprecated qcal defaultNumDays option should be hidden.";
    }
    {
      assertion = options.programs.qcal.settings.visible or true;
      message = "The canonical qcal settings option should remain visible.";
    }
  ];
}
