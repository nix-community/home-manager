{ config, lib, pkgs, ... }:

with lib;

let

  greasemonkeyScript = pkgs.writeText "qutebrowser-greasemonkey.js" ''
    // ==UserScript==
    // @name        foo
    // @namespace   foo
    // @match       https://example.com/*
    // @grant       none
    // ==/UserScript==
  '';

in {
  programs.qutebrowser = {
    enable = true;
    greasemonkey = [ greasemonkeyScript ];
  };

  test.stubs.qutebrowser = { };

  nmt.script = let
    scriptDir = if pkgs.stdenv.hostPlatform.isDarwin then
      ".qutebrowser/greasemonkey"
    else
      ".config/qutebrowser/greasemonkey";
  in ''
    assertFileContent \
      home-files/${scriptDir}/qutebrowser-greasemonkey.js \
      ${greasemonkeyScript}
  '';
}
