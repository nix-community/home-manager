{ pkgs, ... }:
let
  chromium = "chromium";
  package = "hello";
in
{
  programs.${chromium} = {
    enable = true;
    package = pkgs.${package};
  };

  test.asserts.assertions.expected = [
    "Cannot set `package` to `${package}` for ${chromium}. Use one of the packages in `supportedBrowsers` instead."
  ];
}
