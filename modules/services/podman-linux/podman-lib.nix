{ lib, config, ... }:

with lib;

let
  normalizeKeyValue = k: v:
    let
      v' = (if builtins.isBool v then
        (if v then "true" else "false")
      else if builtins.isAttrs v then
        (concatStringsSep ''

          ${k}='' (mapAttrsToList normalizeKeyValue v))
      else
        builtins.toString v);
    in if builtins.isNull v then "" else "${k}=${v'}";

  primitiveAttrs = with types; attrsOf (either primitive (listOf primitive));
  primitiveList = with types; listOf primitive;
  primitive = with types; nullOr (oneOf [ bool int str path ]);

  toQuadletIni = generators.toINI {
    listsAsDuplicateKeys = true;
    mkKeyValue = normalizeKeyValue;
  };

  # meant for ini. favours b when two values are unmergeable
  deepMerge = a: b:
    foldl' (result: key:
      let
        aVal = if builtins.hasAttr key a then a.${key} else null;
        bVal = if builtins.hasAttr key b then b.${key} else null;

        # check if the types inside a list match the type of a primitive
        listMatchesType = (list: val:
          isList list && builtins.length list > 0
          && builtins.typeOf (builtins.head list) == builtins.typeOf val);
      in if isAttrs aVal && isAttrs bVal then
        result // { ${key} = deepMerge aVal bVal; }
      else if isList aVal && isList bVal then
        result // { ${key} = aVal ++ bVal; }
      else if aVal == bVal then
        result // { ${key} = aVal; }
      else if aVal == null then
        result // { ${key} = bVal; }
      else if bVal == null then
        result // { ${key} = aVal; }
      else if isList aVal && listMatchesType aVal bVal then
        result // { ${key} = aVal ++ [ bVal ]; }
      else if isList bVal && listMatchesType bVal aVal then
        result // { ${key} = [ aVal ] ++ bVal; }
      else if builtins.typeOf aVal == builtins.typeOf bVal then
        result // { ${key} = bVal; }
      else
        result // { ${key} = bVal; }) a (builtins.attrNames b);
in {
  inherit primitiveAttrs;
  inherit primitiveList;
  inherit primitive;
  inherit toQuadletIni;
  inherit deepMerge;

  buildConfigAsserts = quadletName: extraConfig:
    let
      configRules = {
        Build = { ImageTag = (with types; listOf str); };
        Container = { ContainerName = types.enum [ quadletName ]; };
        Network = { NetworkName = types.enum [ quadletName ]; };
        Volume = { VolumeName = types.enum [ quadletName ]; };
      };

      # Function to build assertions for a specific section and its attributes.
      buildSectionAsserts = section: attrs:
        if builtins.hasAttr section configRules then
          flatten (mapAttrsToList (attrName: attrValue:
            if builtins.hasAttr attrName configRules.${section} then [{
              assertion = configRules.${section}.${attrName}.check attrValue;
              message = "In '${quadletName}' config. ${section}.${attrName}: '${
                  toString attrValue
                }' does not match expected type: ${
                  configRules.${section}.${attrName}.description
                }";
            }] else
              [ ]) attrs)
        else
          [ ];

      checkImageTag = extraConfig:
        let
          imageTags = (extraConfig.Build or { }).ImageTag or [ ];
          containsRequiredTag =
            builtins.elem "homemanager/${quadletName}" imageTags;
          imageTagsStr = concatMapStringsSep ''" "'' toString imageTags;
        in [{
          assertion = imageTags == [ ] || containsRequiredTag;
          message = ''
            In '${quadletName}' config. Build.ImageTag: '[ "${imageTagsStr}" ]' does not contain 'homemanager/${quadletName}'.'';
        }];

      # Flatten assertions from all sections in `extraConfig`.
    in flatten (concatLists [
      (mapAttrsToList buildSectionAsserts extraConfig)
      (checkImageTag extraConfig)
    ]);

  extraConfigType = with types;
    attrsOf (attrsOf (oneOf [ primitiveAttrs primitiveList primitive ]));

  # input expects a list of quadletInternalType with all the same resourceType
  generateManifestText = quadlets:
    let
      # create a list of all unique quadlet.resourceType in quadlets
      quadletTypes = unique (map (quadlet: quadlet.resourceType) quadlets);
      # if quadletTypes is > 1, then all quadlets are not the same type
      allQuadletsSameType = length quadletTypes <= 1;

      # ensures the service name is formatted correctly to be easily read
      #   by the activation script and matches `podman <resource> ls` output
      formatServiceName = quadlet:
        let
          # remove the podman- prefix from the service name string
          strippedName =
            builtins.replaceStrings [ "podman-" ] [ "" ] quadlet.serviceName;
          # specific logic for writing the unit name goes here. It should be
          #   identical to what `podman <resource> ls` shows
        in {
          "build" = strippedName;
          "container" = strippedName;
          "image" = strippedName;
          "network" = strippedName;
          "volume" = strippedName;
        }."${quadlet.resourceType}";
    in if allQuadletsSameType then ''
      ${concatStringsSep "\n"
      (map (quadlet: formatServiceName quadlet) quadlets)}
    '' else
      abort ''
        All quadlets must be of the same type.
          Quadlet types in this manifest: ${concatStringsSep ", " quadletTypes}
      '';

  # podman requires setuid on newuidmad, so it cannot be provided by pkgs.shadow
  # Including all possible locations in PATH for newuidmap is a workaround.
  # NixOS provides a 'wrapped' variant at /run/wrappers/bin/newuidmap.
  # Other distros must install the 'uidmap' package, ie for ubuntu: apt install uidmap.
  # Extra paths are added to handle where distro package managers may put the uidmap binaries.
  #
  # Tracking for a potential solution: https://github.com/NixOS/nixpkgs/issues/138423
  newuidmapPaths = "/run/wrappers/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  removeBlankLines = text:
    let
      lines = splitString "\n" text;
      nonEmptyLines = filter (line: line != "") lines;
    in concatStringsSep "\n" nonEmptyLines;
}
