{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      firefox-unwrapped = pkgs.runCommandLocal "firefox-0" {
        meta.description = "I pretend to be Firefox";
        passthru.gtk3 = null;
      } ''
        mkdir -p "$out"/{bin,lib/firefox}
        touch "$out/bin/firefox"
        chmod 755 "$out/bin/firefox"
        echo "Name=Firefox" > "$out/lib/firefox/application.ini"
      '';

      librewolf-unwrapped = pkgs.runCommandLocal "librewolf-0" {
        meta.description = "I pretend to be LibreWolf";
        passthru.gtk3 = null;
        passthru.extraPrefsFiles = null;
        passthru.extraPoliciesFiles = null;
      } ''
        mkdir -p "$out"/{bin,lib/librewolf}
        touch "$out/bin/librewolf"
        chmod 755 "$out/bin/librewolf"
        echo "Name=LibreWolf" > "$out/lib/librewolf/application.ini"
      '';
    })
  ];
}
