{
  nix.gc = {
    automatic = true;
    frequency = "00:02:03";
  };

  test.asserts.assertions.expected = [
    "On Darwin nix.gc.frequency must be one of: hourly, daily, weekly, monthly, semiannually, annually."
  ];
}
