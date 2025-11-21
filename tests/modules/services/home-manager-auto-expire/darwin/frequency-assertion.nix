{
  services.home-manager.autoExpire = {
    enable = true;
    frequency = "00:02:00";
  };

  test.asserts.assertions.expected = [
    "On Darwin services.home-manager.autoExpire.frequency must be one of: hourly, daily, weekly, monthly, semiannually, annually."
  ];
}
