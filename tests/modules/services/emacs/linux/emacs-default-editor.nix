{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      # Use `cat` instead of `echo` to prevent arguments from being
      # interpreted as an option.
      emacs = pkgs.writeShellScriptBin "emacsclient" ''${pkgs.coreutils}/bin/cat <<< "$*"'';
    })
  ];

  services.emacs = {
    defaultEditor = true;
    enable = true;
  };

  nmt.script = "source ${
    pkgs.replaceVars ./emacs-default-editor.sh {
      inherit (pkgs) coreutils;
    }
  }";
}
