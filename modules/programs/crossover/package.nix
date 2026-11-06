{
  lib,
  stdenv,
  fetchurl,
  addDriverRunpath,
  autoPatchelfHook,
  makeDesktopItem,
  rpmextract,
  wrapGAppsHook3,
  # The license lives at $homeDir/.cxoffice/etc (see installPhase).
  homeDir,
  # Both package sets, since the dlopen list is applied per bitness.
  pkgs,
  pkgsi686Linux,
  gobject-introspection,
  python3,
  # Resolved through $PATH at runtime, not linked against.
  gzip,
  openssl,
  perl,
  xdg-utils,
  alsa-lib,
  freetype,
  gst_all_1,
  gtk3,
  lcms2,
  libGLU,
  libgphoto2,
  libice,
  libpcap,
  libpng,
  libpulseaudio,
  libsm,
  libunwind,
  libusb1,
  libxcursor,
  libxext,
  libxi,
  libxrandr,
  ocl-icd,
  pcsclite,
  runCommand,
  sane-backends,
  vte,
  zlib,
}:

let
  pname = "crossover";
  version = "26.3.0";

  # New releases: the redirect URL 302s to the current rpm, so the version
  # can be read off the Location header.
  src = fetchurl {
    url = "https://media.codeweavers.com/pub/crossover/cxlinux/demo/crossover-${version}-1.rpm";
    hash = "sha256-M4pHI/sjlOqjr2jz1I0OPPW1p359wKZVcKVnNA9TpNo=";
  };

  # pycairo is required: checkgtk.py treats a missing cairo foreign as
  # "GTK 3 support missing", which blocks the GUI.
  pythonEnv = python3.withPackages (ps: [
    ps.pygobject3
    ps.pycairo
  ]);

  # Libraries Wine loads with dlopen() rather than linking to, so
  # autoPatchelf cannot infer them. Named by attribute path so the list
  # applies to both package sets.
  dlopenLibNames = [
    "SDL2"
    "alsa-lib"
    "cups"
    "dbus"
    "fontconfig"
    "freetype"
    "glib"
    "gnutls"
    "gst_all_1.gst-plugins-base"
    "gst_all_1.gst-plugins-good"
    "gst_all_1.gstreamer"
    "krb5" # libgssapi_krb5 / libkrb5, for AD-authenticating apps
    "libGL"
    "libXinerama"
    "libglvnd"
    "libgphoto2"
    "libpulseaudio"
    "libunwind"
    "libusb1"
    "libv4l" # webcams
    "libx11"
    "libxcomposite"
    "libxcursor"
    "libxext"
    "libxfixes"
    "libxi"
    "libxkbcommon"
    "libxrandr"
    "libxrender"
    "libxxf86vm"
    # cxdiag flags this one as required; the library is tiny and silencing
    # the warning is simpler than arguing about nscd.
    "nssmdns"
    "ocl-icd"
    "pcsclite"
    "sane-backends"
    "systemdLibs" # libudev.so.1
    "unixodbc"
    "vulkan-loader"
    "wayland"
    # C++ apps dlopen() libstdc++ themselves; cxdiag flags it as missing.
    "stdenv.cc.cc.lib"
  ];

  # lib.getLib: autoPatchelf appends "$dep/lib" verbatim, and gnutls /
  # gstreamer / pcsclite default to a `bin` output with an empty lib/.
  dlopenLibs =
    set: map (path: lib.getLib (lib.getAttrFromPath (lib.splitString "." path) set)) dlopenLibNames;

  # The rpm ships a complete 32-bit Wine for win32 bottles; without i686
  # libraries in scope autoPatchelf leaves every ELF32 file unpatched.
  libs32 = dlopenLibs pkgsi686Linux;

  # Two SONAMEs nixpkgs does not ship: libcapi20.so.3 (dead ISDN CAPI 2.0,
  # stubbed to answer "CAPI not installed") and libpcap.so.0.8 (a symlink to
  # the modern libpcap 1.x ABI, which WinPcap works against). Both per
  # bitness.
  mkCapi20Stub =
    stdenv':
    stdenv'.mkDerivation {
      pname = "libcapi20-stub";
      inherit version;
      src = ./capi20.c;
      dontUnpack = true;
      buildPhase = ''
        $CC -shared -fPIC -Wl,-soname,libcapi20.so.3 -o libcapi20.so.3 $src
      '';
      installPhase = ''
        mkdir -p $out/lib
        cp libcapi20.so.3 $out/lib/
      '';
      meta.description = "Stub of the obsolete ISDN CAPI 2.0 library (libcapi20.so.3)";
    };
  capi20Stub64 = mkCapi20Stub stdenv;
  capi20Stub32 = mkCapi20Stub pkgsi686Linux.stdenv;

  mkPcap08Compat =
    libpcap':
    runCommand "libpcap-0.8-compat" { } ''
      mkdir -p $out/lib
      ln -s ${lib.getLib libpcap'}/lib/libpcap.so.1 $out/lib/libpcap.so.0.8
    '';
  pcap08Compat64 = mkPcap08Compat libpcap;
  pcap08Compat32 = mkPcap08Compat pkgsi686Linux.libpcap;

  compatLibs64 = [
    capi20Stub64
    pcap08Compat64
  ];
  compatLibs32 = [
    capi20Stub32
    pcap08Compat32
  ];

  # GStreamer plugins are only seen on GST_PLUGIN_SYSTEM_PATH; the 32-bit
  # plugin dirs have to be stated explicitly, hence one list per bitness.
  gstPluginPkgs = set: [
    set.gst_all_1.gst-plugins-base
    set.gst_all_1.gst-plugins-good
    set.gst_all_1.gst-plugins-bad # h264parse
    set.gst_all_1.gst-plugins-ugly # asfdemux
    set.gst_all_1.gst-libav # avdec_eac3 / avdec_vp9
  ];

  gstPluginDirs64 = map (p: "${lib.getLib p}/lib/gstreamer-1.0") (gstPluginPkgs pkgs);
  gstPluginDirs32 = map (p: "${lib.getLib p}/lib/gstreamer-1.0") (gstPluginPkgs pkgsi686Linux);
  gstPluginDirs = gstPluginDirs64 ++ gstPluginDirs32;

  # The rpm ships a NoDisplay wine.desktop that only launches a given .exe;
  # this is the entry for the CrossOver control panel itself.
  desktopItem = makeDesktopItem {
    name = "crossover";
    desktopName = "CrossOver";
    comment = "Run your Windows® app on Linux";
    exec = "crossover";
    icon = "crossover";
    categories = [ "System" ];
    # The control panel's Wayland app_id is ".crossover-wrapped" (the
    # wrapper-renamed script), which taskbars match against this key.
    startupWMClass = ".crossover-wrapped";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    rpmextract
    autoPatchelfHook
    gobject-introspection # collects the typelibs below into GI_TYPELIB_PATH
    wrapGAppsHook3
    # patchShebangs resolves both interpreters: perl for the launchers,
    # pythonEnv (not bare python3) for the GUI so gi/pycairo still import.
    perl
    pythonEnv
  ];

  buildInputs = [
    alsa-lib
    freetype
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gtk3
    lcms2
    libGLU
    libgphoto2
    libice
    libpng
    libpulseaudio
    libsm
    libunwind
    libusb1
    libxcursor
    libxext
    libxi
    libxrandr
    ocl-icd
    openssl
    pcsclite
    sane-backends
    vte # provides Vte-2.91.typelib, which the install wizard needs
    zlib
  ];

  # dlopenLibs goes on appendRunpaths, not runtimeDependencies: the latter
  # is only applied to executables, but the dlopen()s happen from shared
  # objects (e.g. lib/wine/x86_64-unix/win32u.so).
  runtimeDependencies = dlopenLibs pkgs ++ libs32 ++ compatLibs64 ++ compatLibs32;

  # The GL/Vulkan driver is host state, referenced by path; the plugin dirs
  # must be searchable too, not just libgstreamer.
  appendRunpaths = [
    "${addDriverRunpath.driverLink}/lib"
    "${addDriverRunpath.driverLink}-32/lib"
  ]
  ++ map (p: "${p}/lib") (dlopenLibs pkgs ++ libs32)
  ++ map (p: "${p}/lib") (compatLibs64 ++ compatLibs32)
  ++ gstPluginDirs;

  # The compat libs are provided by RUNPATH above, not by patchelf
  # resolving the pre-1.0 libpcap SONAME.
  autoPatchelfIgnoreMissingDeps = [
    "libcapi20.so.3"
    "libpcap.so.0.8"
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -pv $out
    cp -R ./opt/cxoffice/* $out/

    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/

    for size in 16 32 48 64 128 256; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      cp ./opt/cxoffice/share/icons/''${size}x''${size}/crossover.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/crossover.png
    done

    # perl launchers and bottle-template scripts have #!/usr/bin/perl
    # shebangs, and the GUI #!/usr/bin/env python3; --build is required
    # because strictDeps puts neither interpreter on HOST_PATH.
    patchShebangs --build $out

    # makeWrapper renames every executable to '.<name>-wrapped', and the
    # perl launchers infer their identity from $0; cxname0() strips the
    # rename so `wine` is not mistaken for a winelib app.
    substituteInPlace $out/lib/perl/CXLog.pm \
      --replace-fail '    $name0 =~ s+^.*/++;' \
                     '    $name0 =~ s+^.*/++; $name0 =~ s/^\.//; $name0 =~ s/-wrapped$//;'

    # Python 3.14 defaults multiprocessing to forkserver, which pickles the
    # GTK-holding worker targets; force fork back.
    substituteInPlace $out/lib/python/crossoverui.py \
      --replace-fail 'import multiprocessing' \
                     'import multiprocessing
    multiprocessing.set_start_method("fork", force=True)'
    substituteInPlace $out/lib/python/packageview.py \
      --replace-fail 'import multiprocessing' \
                     'import multiprocessing
    multiprocessing.set_start_method("fork", force=True)'

    # The license is normally written to $CX_ROOT/etc as root via `cxsu`
    # (kdesu/gksu/kdesudo/xdg-su), none of which exist on NixOS. Redirect
    # the license handling to the user's writable cellar instead.
    # bin/cxregister is still the rpm's python script here; the wrap phase
    # renames it to .cxregister-wrapped, so patching it here reaches it.
    substituteInPlace $out/bin/cxregister $out/lib/python/demoutils.py \
      --replace-fail 'os.path.join(cxutils.CX_ROOT, "etc"' \
                     'os.path.join(cxproduct.get_user_dir(), "etc"'
    # The cellar's etc dir does not exist yet, whereas $CX_ROOT/etc does.
    substituteInPlace $out/bin/cxregister \
      --replace-fail '        shutil.copyfile(src_license, dst_license)' \
                     '        os.makedirs(etc_dir, exist_ok=True)
            shutil.copyfile(src_license, dst_license)'
    substituteInPlace $out/lib/python/crossoverui.py \
      --replace-fail 'os.path.join(cxutils.CX_ROOT, "etc"' \
                     'os.path.join(cxproduct.get_user_dir(), "etc"' \
      --replace-fail "os.path.join(cxutils.CX_ROOT, 'etc'" \
                     "os.path.join(cxproduct.get_user_dir(), 'etc'"
    substituteInPlace $out/lib/python/cxregisterui.py \
      --replace-fail 'os.path.join(cxutils.CX_ROOT, "etc"' \
                     'os.path.join(cxproduct.get_user_dir(), "etc"'
    # The patched files reference cxproduct, which cxregister only imports
    # lazily in main() (after install() runs) and the others never import.
    substituteInPlace $out/bin/cxregister \
      --replace-fail 'import cxlog' \
                     'import cxlog
    import cxproduct'
    substituteInPlace $out/lib/python/demoutils.py \
      --replace-fail 'import cxconfig' \
                     'import cxconfig
    import cxproduct'
    substituteInPlace $out/lib/python/cxregisterui.py \
      --replace-fail 'import cxutils' \
                     'import cxutils
    import cxproduct'

    # winemenubuilder.exe bakes the absolute store path of this build into
    # the .lnk launchers it writes; every rebuild changes that path. Rewrite
    # them, whenever cxmenu runs, to invoke bare `wine-crossover` (added in
    # postFixup) on $PATH, which always resolves to the current build.
    # bin/cxmenu is still the rpm's perl script here; the wrap phase renames
    # it to .cxmenu-wrapped.
    substituteInPlace $out/bin/cxmenu \
      --replace-fail '    cxlog("-> Finalization took ", CXLog::cxtime()-$start, " seconds\n");
    }

    exit $rc;' \
                     '    cxlog("-> Finalization took ", CXLog::cxtime()-$start, " seconds\n");
    }

    if (defined $ENV{WINEPREFIX} and -d "$ENV{WINEPREFIX}/desktopdata/cxmenu")
    {
        CXUtils::cxsystem("find", "$ENV{WINEPREFIX}/desktopdata/cxmenu",
                          "-type", "f", "-name", "*.lnk",
                          "-exec", "sed", "-i", "-E",
                          q!s#"/nix/store/[a-z0-9]{32}-crossover-[^"]*/bin/wine"#wine-crossover#!,
                          "{}", "+");
    }

    exit $rc;'

    # winewrapper.exe (32- and 64-bit) runs its own demo check against
    # $CX_ROOT/etc/license.txt in the read-only store; bridge it to the
    # cellar with symlinks. license.sig is only created for accounts
    # without a SHA-256 signature; the dangling symlink is harmless.
    mkdir -p $out/etc
    ln -s ${homeDir}/.cxoffice/etc/license.txt $out/etc/license.txt
    ln -s ${homeDir}/.cxoffice/etc/license.sha256 $out/etc/license.sha256
    ln -s ${homeDir}/.cxoffice/etc/license.sig $out/etc/license.sig

    runHook postInstall
  '';

  # auto-patchelf skips files whose ELF class does not match the target
  # linker, so the 32-bit Wine needs a second pass with the i686 bintools.
  # autoPatchelfLibs is the DT_NEEDED search path (runtimeDependencies only
  # extends RUNPATH), filled from buildInputs; a subshell keeps the i686
  # additions out of the 64-bit pass.
  postFixup = ''
    (
      export NIX_BINTOOLS=${pkgsi686Linux.stdenv.cc.bintools}
      autoPatchelfLibs+=(${lib.concatMapStringsSep " " (p: "${p}/lib") libs32})
      autoPatchelf -- "$out"
    )
    # A non-colliding name for the wine launcher: plain `wine` is taken by
    # the nixpkgs wine package in the profile merge.
    ln -s wine $out/bin/wine-crossover
  '';

  # Fed to wrapGAppsHook3 rather than makeWrapperArgs: with
  # __structuredAttrs the latter reaches makeWrapper unsplit. --prefix, not
  # --suffix, so a python3 earlier on the user's PATH cannot shadow it.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${
        lib.makeBinPath [
          pythonEnv
          openssl.bin
          gzip
          perl
          xdg-utils
        ]
      }"
      # The wrapper is shared by both bitnesses, so the 32-bit plugin dirs
      # ride along; each process skips the foreign-ELF-class ones.
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${lib.concatStringsSep ":" gstPluginDirs32}"
    )
  '';

  __structuredAttrs = true;
  strictDeps = true;

  meta = {
    description = "Run your Windows® app on Linux";
    homepage = "https://www.codeweavers.com/crossover";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    mainProgram = "crossover";
    platforms = [ "x86_64-linux" ];
  };
}
