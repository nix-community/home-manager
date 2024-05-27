{
  nixpkgs.overlays = [
    (final: prev: {
      mpvScript = prev.runCommandLocal "mpvScript" { scriptName = "something"; }
        "mkdir $out";

      mpv-unwrapped = let
        lua = prev.emptyDirectory.overrideAttrs {
          luaversion = "0";
          passthru.withPackages = pkgsFn: prev.emptyDirectory;
        };
        mpv-unwrapped' = prev.mpv-unwrapped.override { inherit lua; };
      in mpv-unwrapped'.overrideAttrs {
        buildInputs = [ ];
        nativeBuildInputs = [ ];
        builder = prev.writeShellScript "dummy" ''
          PATH=${final.coreutils}/bin
          mkdir -p $dev $doc $man $out/bin $out/Applications/mpv.app/Contents/MacOS
          touch $out/bin/{mpv,umpv} \
                $out/Applications/mpv.app/Contents/MacOS/{mpv,mpv-bundle}
          chmod +x $out/bin/{mpv,umpv} \
                   $out/Applications/mpv.app/Contents/MacOS/{mpv,mpv-bundle}
        '';
      };
    })
  ];

  test.stubs = { yt-dlp = { }; };
}
