{
  config = {
    programs.msmtp = {
      enable = true;
      accountOrder = [ "missing" ];
    };

    test.asserts.assertions.expected = [
      "programs.msmtp.accountOrder contains an unknown account name."
    ];
  };
}
