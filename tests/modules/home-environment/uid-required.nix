{
  home.stateVersion = "26.05";
  # Test that home.uid is required for stateVersion 26.05+
  home.uid = null;

  test.asserts.assertions.expected = [
    ''
      User ID (UID) could not be determined. Please set 'home.uid' to your
      user's UID. You can find your UID by running 'id -u' in your terminal.

      If you are using Home Manager as a NixOS or nix-darwin module, you can
      alternatively set 'users.users.<name>.uid' in your system configuration.
    ''
  ];
}
