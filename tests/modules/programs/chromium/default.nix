{ lib, pkgs, ... }:
{
  chromium-basic-options = ./basic-options.nix;
  chromium-extension-version-without-crxpath = ./extension-version-without-crxpath.nix;
  chromium-google-chrome-options = ./google-chrome-options.nix;
  chromium-google-chrome-package-assertion = ./google-chrome-package-assertion.nix;
  chromium-null-package-command-line-args = ./null-package-command-line-args.nix;
  chromium-plasma-support-command-line-args = ./plasma-support-command-line-args.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  chromium-brave-package-routing-linux = ./brave-package-routing-linux.nix;
  chromium-google-chrome-extensions-linux = ./google-chrome-extensions-linux.nix;
  chromium-ungoogled-chromium-extensions-linux = ./ungoogled-chromium-extensions-linux.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  chromium-google-chrome-extensions-darwin = ./google-chrome-extensions-darwin.nix;
}
