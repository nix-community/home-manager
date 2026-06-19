{
  config,
  pkgs,
  realPkgs,
  ...
}:

let
  configFile = "home-files/.config/fontconfig/conf.d/10-hm-fonts.conf";
  fontPackage = pkgs.runCommandLocal "hm-fontconfig-test-font" { } ''
    mkdir -p $out/share/fonts/misc
    cat > $out/share/fonts/misc/hm-test-font.bdf <<'EOF'
    STARTFONT 2.1
    FONT -HM-Test-Font-Medium-R-Normal--8-80-75-75-C-50-ISO10646-1
    SIZE 8 75 75
    FONTBOUNDINGBOX 5 8 0 -1
    STARTPROPERTIES 8
    FONT_ASCENT 7
    FONT_DESCENT 1
    FOUNDRY "HM"
    FAMILY_NAME "HM Test Font"
    WEIGHT_NAME "Medium"
    SLANT "R"
    SETWIDTH_NAME "Normal"
    CHARSET_REGISTRY "ISO10646"
    CHARSET_ENCODING "1"
    ENDPROPERTIES
    CHARS 1
    STARTCHAR A
    ENCODING 65
    SWIDTH 500 0
    DWIDTH 5 0
    BBX 5 7 0 0
    BITMAP
    70
    88
    88
    F8
    88
    88
    88
    ENDCHAR
    ENDFONT
    EOF
  '';
in
{
  fonts.fontconfig = {
    enable = true;
    packages = [ fontPackage ];
  };

  # Use `realPkgs` here since the discovery check relies on the `fc-list`
  # binary. The font package itself is generated locally by this test.
  test.unstubs = [ (_self: _super: { inherit (realPkgs) fontconfig; }) ];

  nmt.script = ''
    assertFileExists ${configFile}
    assertFileRegex activate 'run .*/bin/fc-cache -f'
    assertFileContent ${configFile} ${pkgs.writeText "font-packages.conf" ''
      <?xml version="1.0" encoding="utf-8"?>
      <fontconfig>
        <cachedir>${config.home.path}/lib/fontconfig/cache</cachedir>
        <description>Add fonts in the Nix user profile</description>
        <dir>${fontPackage}</dir>
        <dir>${config.home.path}/lib/X11/fonts</dir>
        <dir>${config.home.path}/share/fonts</dir>
        <dir>${config.home.profileDirectory}/lib/X11/fonts</dir>
        <dir>${config.home.profileDirectory}/share/fonts</dir>
        <include ignore_missing="yes">${config.home.path}/etc/fonts/conf.d</include>
        <include ignore_missing="yes">${config.home.path}/etc/fonts/fonts.conf</include>
      </fontconfig>
    ''}

    XDG_CACHE_HOME="$TMPDIR" \
      FONTCONFIG_FILE="$TESTED/${configFile}" \
      ${realPkgs.fontconfig}/bin/fc-list \
      | grep -F "${fontPackage}/share/fonts/misc/hm-test-font.bdf" >/dev/null
  '';
}
