{ pkgs, ... }:
let
  package = "google-chrome";
in
{
  programs.chromium = {
    enable = true;
    package = pkgs.${package};
  };

  test.asserts.assertions.expected = [
    "Cannot set `package` to `${package}` for chromium. Use `programs.${package}.enable = true;` instead."
  ];
}
