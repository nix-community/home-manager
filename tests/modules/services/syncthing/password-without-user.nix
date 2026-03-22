{
  services.syncthing = {
    enable = true;
    passwordFile = ./fake-password-file;
  };

  test.asserts.assertions.expected = [
    "Missing username for the provided password to connect to the GUI."
  ];
}
