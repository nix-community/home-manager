{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    assertMsg
    concatLines
    escapeShellArgs
    floor
    getExe
    head
    hm
    imap
    isList
    literalExpression
    maintainers
    match
    mkEnableOption
    mkIf
    mkOption
    mkOptionType
    mkPackageOption
    optionals
    platforms
    removeSuffix
    toInt
    types
    ;
  inherit (pkgs)
    writeShellScript
    ;

  listOrListOfListOf =
    t:
    types.addCheck (with types; listOf (either t (listOf t))) (
      values:
      values == [ ]
      || (
        let
          isMultiGpu = isList (head values);
        in
        lib.all (value: isList value == isMultiGpu) values
      )
    );

  percentStr = mkOptionType {
    inherit (types.str) merge;
    name = "percentStr";
    description = "percentage";
    descriptionClass = "noun";
    check = x: types.str.check x && match "[0-9]([0-9]+)?%" x != null;
  };

  percentStrToInt = x: toInt (removeSuffix "%" x);

  percentStrBetween =
    lowest: highest:
    assert assertMsg (lowest <= highest) "percentStrBetween: lowest must be smaller than highest";
    types.addCheck percentStr (
      v:
      let
        i = percentStrToInt v;
      in
      i >= lowest && i <= highest
    )
    // {
      name = "percentStrBetween";
      description = "percentage between ${toString lowest}% and ${toString highest}% (both inclusive)";
    };

  cfg = config.services.nvibrant;
in

{
  meta.maintainers = with maintainers; [ mikaeladev ];

  options.services.nvibrant = {
    enable = mkEnableOption "nvibrant";

    package = mkPackageOption pkgs "nvibrant" { };

    dithering = mkOption {
      type = with types; listOrListOfListOf (nullOr (either bool (enum [ "auto" ])));
      default = [ ];
      example = literalExpression ''
        [
          true   # HDMI
          null   # DP1
          false  # DP2
        ]
      '';
      description = ''
        Whether to enable or disable dithering for your monitor(s).

        Values should match the order of physical ports on your GPU. If a null
        value is passed, nvibrant will default to false (even if a device is
        connected at that port).

        If you have multiple GPUs, you can pass a list of lists in order of
        device.
      '';
    };

    vibrancy = mkOption {
      type = with types; listOrListOfListOf (nullOr (percentStrBetween 0 200));
      default = [ ];
      example = literalExpression ''
        [
          "0%"    # HDMI
          null    # DP1
          "200%"  # DP2
        ]
      '';
      description = ''
        The vibrancy level for your monitor(s).

        Values should match the order of physical ports on your GPU. If a null
        value is passed, nvibrant will default to 100% (even if a device is
        connected at that port).

        If you have multiple GPUs, you can pass a list of lists in order of
        device.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.nvibrant" pkgs platforms.linux)
      {
        assertion = !(cfg.dithering == [ ] && cfg.vibrancy == [ ]);
        message = "Either `services.nvibrant.dithering` or `services.nvibrant.vibrancy` must be set";
      }
    ];

    systemd.user.services.nvibrant = {
      Unit = {
        Description = "Applies nvibrant";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart =
          let
            clampMax = x: y: if x > y then y else x;
            percentIntToValue = x: clampMax (floor (10.24 * x - 1024)) 1023;

            mkDitheringArgs =
              value:
              escapeShellArgs (
                map (
                  v:
                  if v == "auto" then
                    0
                  else if v == true then
                    1
                  else
                    2
                ) value
              );

            mkVibrancyArgs =
              value:
              escapeShellArgs (map (v: percentIntToValue (if v == null then 100 else percentStrToInt v)) value);

            mkLines =
              fn: list:
              if isList (head list) then
                imap (i: v: "NVIDIA_GPU=${toString (i - 1)} ${fn v}") list
              else
                [ (fn list) ];

            binPath = getExe cfg.package;

            ditheringLines = optionals (cfg.dithering != [ ]) (
              mkLines (value: "ATTRIBUTE=dithering ${binPath} ${mkDitheringArgs value}") cfg.dithering
            );

            vibrancyLines = optionals (cfg.vibrancy != [ ]) (
              mkLines (value: "${binPath} ${mkVibrancyArgs value}") cfg.vibrancy
            );

            scriptLines = concatLines (ditheringLines ++ vibrancyLines);
          in
          writeShellScript "apply-nvibrant" scriptLines;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
