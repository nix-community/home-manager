{ config, lib, pkgs, ... }:

with lib;

let

  hmTypes = import ../lib/types.nix { inherit lib; };

  cfg = config.programs.emacs;
  emacsBinPath = "${cfg.finalPackage}/bin";

  # Copied from all-packages.nix, with modifications to support
  # overrides.
  emacsPackages =
    let
      epkgs = pkgs.emacsPackagesGen cfg.package;
    in
      epkgs.overrideScope' cfg.overrides;
  emacsWithPackages = emacsPackages.emacsWithPackages;

  # Adapted from upstream emacs.desktop
  clientDesktopFile = pkgs.writeTextFile {
    name = "emacsclient.desktop";
    destination = "/share/applications/emacsclient.desktop";
    text = ''
      [Desktop Entry]
      Name=Emacs client
      GenericName=Text Editor
      Comment=Edit text
      MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
      Exec=${emacsBinPath}/emacsclient ${concatStringsSep " " cfg.client.args} %F
      Icon=emacs
      Type=Application
      Terminal=false
      Categories=Development;TextEditor;
      StartupWMClass=Emacs
      Keywords=Text;Editor;
    '';
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.emacs = {
      enable = mkEnableOption "Emacs";

      client = {
        enable = mkOption {
          type = types.bool;
          default = false;
          example = "false";
          description = "Enable the Emacs client desktop file.";
        };
        args = mkOption {
          type = with types; listOf str;
          default = [ "-c" ];
          description = ''
            Command-line arguments to pass to <command>emacsclient</command>.
          '';
        };
      };

      package = mkOption {
        type = types.package;
        default = pkgs.emacs;
        defaultText = literalExample "pkgs.emacs";
        example = literalExample "pkgs.emacs25-nox";
        description = "The Emacs package to use.";
      };

      extraPackages = mkOption {
        default = self: [];
        type = hmTypes.selectorFunction;
        defaultText = "epkgs: []";
        example = literalExample "epkgs: [ epkgs.emms epkgs.magit ]";
        description = ''
          Extra packages available to Emacs. To get a list of
          available packages run:
          <command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A emacsPackages</command>.
        '';
      };

      overrides = mkOption {
        default = self: super: {};
        type = hmTypes.overlayFunction;
        defaultText = "self: super: {}";
        example = literalExample ''
          self: super: rec {
            haskell-mode = self.melpaPackages.haskell-mode;
            # ...
          };
        '';
        description = ''
          Allows overriding packages within the Emacs package set.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = ''
          The Emacs package including any overrides and extra packages.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      [ cfg.finalPackage ]
      ++ lib.optional cfg.client.enable clientDesktopFile;
    programs.emacs.finalPackage = emacsWithPackages cfg.extraPackages;
  };
}
