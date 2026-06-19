{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  stubType = types.submodule (
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = "dummy";
          description = "The stub package name.";
        };

        outPath = mkOption {
          type = types.nullOr types.str;
          default = "@${name}@";
          defaultText = lib.literalExpression ''"@''${name}@"'';
        };

        version = mkOption {
          type = types.nullOr types.str;
          default = null;
          defaultText = lib.literalExpression "pkgs.\${name}.version or null";
        };

        buildScript = mkOption {
          type = types.str;
          default = defaultBuildScript;
        };

        extraAttrs = mkOption {
          type = types.attrsOf types.anything;
          default = { };
        };
      };
    }
  );

  defaultBuildScript = "mkdir $out";

  dummyPackage = pkgs.runCommandLocal "dummy" { meta.mainProgram = "dummy"; } defaultBuildScript;

  mkStubPackage =
    {
      name ? "dummy",
      outPath ? null,
      version ? null,
      buildScript ? defaultBuildScript,
      extraAttrs ? { },
    }:
    let
      pkg =
        if name == "dummy" && buildScript == defaultBuildScript then
          dummyPackage
        else
          pkgs.runCommandLocal name {
            pname = name;
            meta.mainProgram = name;
          } buildScript;

      drvExtraAttrs = lib.filterAttrs (_: v: !lib.isFunction v) extraAttrs;

      outerExtraAttrs = lib.filterAttrs (_: lib.isFunction) extraAttrs;

      overriddenPkg =
        if drvExtraAttrs == { } then
          pkg
        else
          pkg.overrideAttrs (old: lib.recursiveUpdate old drvExtraAttrs);

      stubbedPkg =
        overriddenPkg
        // outerExtraAttrs
        // lib.optionalAttrs (outPath != null) {
          inherit outPath;

          # Prevent getOutput from descending into outputs
          outputSpecified = true;

          # Allow the original package to be used in derivation inputs
          __spliced = {
            buildHost = overriddenPkg;
            hostTarget = overriddenPkg;
          };
        }
        // lib.optionalAttrs (version != null) { inherit version; };
    in
    stubbedPkg;

  runActivation =
    name: activation:
    let
      activationScript = pkgs.writeScript name activation.data;
    in
    ''
      substitute ${activationScript} $TMPDIR/${name} --subst-var TMPDIR
      chmod +x $TMPDIR/${name}
      $TMPDIR/${name}
    '';

  runMutableConfigTest =
    {
      home ? "$TMPDIR/hm-user",
      files ? { },
      expected ? { },
      setup ? "",
      assertions ? "",
      idempotent ? true,
      idempotentPaths ? lib.attrNames expected,
    }:
    let
      seedFiles = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (path: source: ''
          mkdir -p "$(dirname "$HOME/${path}")"
          cat ${source} > "$HOME/${path}"
        '') files
      );

      assertExpected = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (path: expectedContent: ''
          assertFileExists "$HOME/${path}"
          assertFileContent "$HOME/${path}" "${expectedContent}"
        '') expected
      );

      idempotentFiles = lib.concatStringsSep " " (map (path: ''"$HOME/${path}"'') idempotentPaths);
    in
    ''
      export HOME=${home}

      ${seedFiles}
      ${setup}

      ${runActivation "mutable-config-activation" config.home.activation.mutableConfigMerge}

      ${assertExpected}
      ${assertions}

      ${lib.optionalString (idempotent && idempotentPaths != [ ]) ''
        pre_hashes="$(sha256sum ${idempotentFiles})"
        pre_inodes="$(stat -c '%i %n' ${idempotentFiles})"

        $TMPDIR/mutable-config-activation

        post_hashes="$(sha256sum ${idempotentFiles})"
        post_inodes="$(stat -c '%i %n' ${idempotentFiles})"

        test "$pre_hashes" = "$post_hashes"
        test "$pre_inodes" = "$post_inodes"

        ${assertExpected}
        ${assertions}
      ''}
    '';

in
{
  options.test = {
    stubs = mkOption {
      type = types.attrsOf stubType;
      default = { };
      description = "Package attributes that should be replaced by a stub package.";
    };

    stubOverlays = mkOption {
      type = types.anything;
      default = [ ];
      internal = true;
    };

    unstubs = mkOption {
      type = types.listOf types.anything;
      default = [ ];
    };
  };

  config = {
    lib.test.mkStubPackage = mkStubPackage;
    lib.test.runActivation = runActivation;
    lib.test.runMutableConfig = runActivation "mutable-config-activation" config.home.activation.mutableConfigMerge;
    lib.test.runMutableConfigTest = runMutableConfigTest;

    test.stubOverlays =
      lib.optional (config.test.stubs != { }) (
        _self: super:
        lib.mapAttrs (
          n: v:
          builtins.traceVerbose "${n} - stubbed" (
            mkStubPackage (
              v
              // lib.optionalAttrs (v.version == null) {
                version = super.${n}.version or null;
              }
            )
          )
        ) config.test.stubs
      )
      ++ config.test.unstubs;
  };
}
