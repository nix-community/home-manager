{ lib, pkgs, ... }:
{
  chromium-basic-options = ./basic-options.nix;
  chromium-google-chrome-options = ./google-chrome-options.nix;
  chromium-google-chrome-package-routing = ./google-chrome-package-routing.nix;
  chromium-native-messaging-google-chrome = ./native-messaging-google-chrome.nix;
  chromium-null-package-command-line-args = ./null-package-command-line-args.nix;
  chromium-plasma-support-command-line-args = ./plasma-support-command-line-args.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  chromium-google-chrome-extensions-linux = ./google-chrome-extensions-linux.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  chromium-google-chrome-dev-package-routing-darwin = ./google-chrome-dev-package-routing-darwin.nix;
  chromium-google-chrome-extensions-darwin = ./google-chrome-extensions-darwin.nix;
}
