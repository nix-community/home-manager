{
  nix.gc = {
    automatic = true;
    dates = "00:02:03";
  };

  test.asserts.assertions.expected = [
    "On Darwin nix.gc.dates.* must be one of: hourly, daily, weekly, monthly, semiannually, annually."
  ];
}
