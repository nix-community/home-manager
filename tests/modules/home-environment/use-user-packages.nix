{
  home.useUserPackages = true;

  test.asserts.warnings.expected = [
    "You have enabled `home.useUserPackages`, but this option has no effect outside of NixOS configurations."
  ];
}
