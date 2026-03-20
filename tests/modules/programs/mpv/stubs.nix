{ lib, pkgs, ... }:

let
  mkMpvBuildScript =
    {
      scripts ? [ ],
      extraMakeWrapperArgs ? [ ],
    }:
    let
      wrapperArgMarkers = lib.concatStringsSep "\n" extraMakeWrapperArgs;
      scriptMarkers = lib.concatMapStringsSep "\n" (
        script: "script=${script}/share/mpv/scripts/${script.scriptName}"
      ) scripts;
      markers = lib.concatStringsSep "\n" (
        lib.filter (marker: marker != "") [
          wrapperArgMarkers
          scriptMarkers
        ]
      );
    in
    ''
      mkdir -p $out/bin $out/share/applications
      echo "Name=mpv" > $out/share/applications/mpv.desktop

      cat > $out/bin/mpv <<EOF
      #!${pkgs.runtimeShell}
      # stubbed mpv binary for home-manager tests
      ${markers}
      exit 0
      EOF
      chmod +x $out/bin/mpv
    '';
in
{
  test.stubs = {
    mpv = {
      name = "mpv";
      outPath = null;
      buildScript = mkMpvBuildScript { };

      extraAttrs = rec {
        override =
          {
            scripts ? [ ],
            extraMakeWrapperArgs ? [ ],
          }:
          let
            pkg =
              pkgs.runCommandLocal "mpv"
                {
                  pname = "mpv";
                  meta.mainProgram = "mpv";
                }
                (mkMpvBuildScript {
                  inherit scripts extraMakeWrapperArgs;
                });
          in
          pkg
          // {
            inherit override;
          };
      };
    };

    mpv-unwrapped = {
      name = "mpv-unwrapped";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications
        echo "Name=mpv" > $out/share/applications/mpv.desktop

        cp ${pkgs.writeShellScript "mpv" "exit 0"} $out/bin/mpv
        chmod +x $out/bin/mpv
      '';

      extraAttrs = {
        meta =
          let
            stub = "stub";
          in
          {
            description = stub;
            longDescription = stub;
            homepage = stub;
            mainProgram = stub;
            license = [ stub ];
            maintainers = [ stub ];
            teams = [ stub ];
            platforms = lib.platforms.all;
          };
      };
    };

    mpvScript = {
      extraAttrs = {
        scriptName = "mpvScript";
      };
    };
  };
}
