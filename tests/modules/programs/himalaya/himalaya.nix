{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        himalaya = {
          enable = true;

          settings = { default-page-size = 50; };
        };

        imap.port = 995;
        smtp.port = 465;
      };
    };

    programs.himalaya = {
      enable = true;
      settings = { downloads-dir = "/data/download"; };
    };

    nixpkgs.overlays =
      [ (self: super: { himalaya = pkgs.writeScriptBin "dummy-alot" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/himalaya/config.toml
      assertFileContent home-files/.config/himalaya/config.toml ${
        ./himalaya-expected.toml
      }
    '';
  };
}

