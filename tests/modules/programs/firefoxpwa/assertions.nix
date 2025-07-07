{
  programs.firefoxpwa = {
    enable = true;
    package = null;
    profiles = {
      "INVALID" = { };
      "0123456789ABCDEFGHJKMNPQRS".sites."00000000000000000000000000" = {
        name = "MDN Web Docs";
        url = "https://developer.mozilla.org/";
        manifestUrl = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
      };
      "ZYXWVTSRQPNMKJHGFEDCBA9876".sites."00000000000000000000000000" = {
        name = "MDN Web Docs";
        url = "https://developer.mozilla.org/";
        manifestUrl = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
      };
    };
  };
  test.asserts.assertions.expected = [
    ''
      ULID 'INVALID' at 'programs.firefoxpwa.profiles' must be 26 characters, but is
      7 characters long.
    ''
    ''
      ULID 'INVALID' at 'programs.firefoxpwa.profiles' is only allowed to contain
      characters '0123456789ABCDEFGHJKMNPQRSTVWXYZ', but contains 'ILI'.
    ''
    ''
      Site with ULID '00000000000000000000000000' can only be present in one profile, but is present in
      profiles '0123456789ABCDEFGHJKMNPQRS', 'ZYXWVTSRQPNMKJHGFEDCBA9876'.
    ''
  ];
}
