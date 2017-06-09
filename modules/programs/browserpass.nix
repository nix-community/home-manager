{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix;

let
  browsers = {
    chrome = 1;
    chromium = 2;
    firefox = 3;
    vivaldi = 4;
  };
in {
  options = {
    programs.browserpass = {
      enable = mkEnableOption "the browserpass extension host application";

      browsers = mkOption {
        type = types.listOf types.str;
        default = builtins.attrNames browsers;
        example = [ "firefox" ];
        description = "Which browsers to install browserpass for";
      };
    };
  };

  config = mkIf config.programs.browserpass.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.is64bit;
        message = "Only 64-bit is supported";
      }
      {
        assertion = builtins.all (x: builtins.any (y: x == y) (builtins.attrNames browsers)) config.programs.browserpass.browsers;
        message = "Unsupported browser, must be one of: ${toString (builtins.attrNames browsers)}";
      }
      {
        assertion = (builtins.getEnv "USER") != "root";
        message = "root install not supported";
      }
    ];

    home.activation.browserpass = let
      browserpass = pkgs.stdenv.mkDerivation (let
        package = with pkgs.stdenv; if isLinux then
            {
              system = "linux64";
              sha256 = "1h1figz97jgzfykrq2kr8ywxzbbrfk9haqhalc65w6n7cks0wgx8";
            }
          else if isDarwin then
            {
              system = "darwinx64";
              sha256 = "199zr0nvrm9pz0f39dzfz67m85b0k3c4l6hf98377w89vdcp28r5";
            }
          else if isOpenBSD then
            {
              system = "openbsd64";
              sha256 = "1yi861wgx1mwzkxc9qyhx3s8g0cyvsdac9f1la2knhfgr3g9rr7h";
            }
          else abort "${currentSystem} not supported";
      in rec {
        name = "browserpass-${version}-bin_for-home-manager";
        version = "1.0.4";

        src = pkgs.fetchzip {
          inherit (package) sha256;
          url = "https://github.com/dannyvankooten/browserpass/releases/download/${version}/browserpass-${package.system}.zip";
          stripRoot = false;
        };

        postUnpack = ''
          # Files are not writable since they were copied from the nix store.
          # That causes the install to fail next time because we can't overwrite them.
          echo "chmod u+w \"\$TARGET_DIR/\$APP_NAME.json\"" >> browserpass-${package.system}.zip/install.sh
          echo "[ \"\$BROWSER\" != ${toString browsers.firefox} ] && chmod u+w \"\$TARGET_DIR\"/../policies/managed/\"\$APP_NAME.json\" || :" >> browserpass-${package.system}.zip/install.sh
          touch --date=@$SOURCE_DATE_EPOCH browserpass-${package.system}.zip/install.sh
        '';

        installPhase = ''
          mkdir $out
          mv * $out/
        '';
      });
    in dagEntryBefore ["writeBoundary"] (builtins.concatStringsSep "" (map (browser: ''
      $DRY_RUN_CMD ${browserpass}/install.sh <<EOF
      ${toString browsers.${browser}}
      EOF
    '') config.programs.browserpass.browsers));
  };
}
