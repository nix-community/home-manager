{
  services.borgmatic = {
    enable = true;
    frequency = "00:02:00";
  };

  test.asserts.assertions.expected = [
    "On Darwin services.borgmatic.frequency must be one of: hourly, daily, weekly, monthly, semiannually, annually."
  ];
}
