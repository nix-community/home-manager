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
      ULID 'INVALID' at 'programs.firefoxpwa.profiles' must only contain characters
      '0123456789ABCDEFGHJKMNPQRSTVWXYZ', but contains 'ILI'.
    ''
    ''
      Site with ULID '00000000000000000000000000' must be present in exactly one profile, but is present
      in 2 profiles, namely '0123456789ABCDEFGHJKMNPQRS', 'ZYXWVTSRQPNMKJHGFEDCBA9876'.
    ''
  ];
}
