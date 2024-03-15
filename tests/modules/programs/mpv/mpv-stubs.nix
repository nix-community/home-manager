{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      mpvScript = pkgs.runCommandLocal "mpvScript" { scriptName = "something"; }
        "mkdir $out";

      mpv-unwrapped = super.mpv-unwrapped.overrideAttrs {
        builder = pkgs.writeShellScript "dummy" ''
          PATH=${pkgs.coreutils}/bin
          mkdir -p $dev $doc $man $out/bin $out/Applications/mpv.app/Contents/MacOS
          touch $out/bin/{mpv,umpv} \
                $out/Applications/mpv.app/Contents/MacOS/{mpv,mpv-bundle}
          chmod +x $out/bin/{mpv,umpv} \
                   $out/Applications/mpv.app/Contents/MacOS/{mpv,mpv-bundle}
        '';
      };

      lua = pkgs.emptyDirectory.overrideAttrs {
        luaversion = "0";
        withPackages = ps: pkgs.emptyDirectory;
      };
    })
  ];

  test.stubs = { yt-dlp = { }; };
}
