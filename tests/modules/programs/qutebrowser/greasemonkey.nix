{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.qutebrowser = {
      enable = true;

      greasemonkey = [
        (pkgs.writeText "qutebrowser-greasemonkey.js" ''
          // ==UserScript==
          // @name        foo
          // @namespace   foo
          // @match       https://example.com/*
          // @grant       none
          // ==/UserScript==
        '')
      ];
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
        ${
          pkgs.writeText "qutebrowser-expected-greasemonkey" ''
            // ==UserScript==
            // @name        foo
            // @namespace   foo
            // @match       https://example.com/*
            // @grant       none
            // ==/UserScript==
          ''
        }
    '';
  };
}
