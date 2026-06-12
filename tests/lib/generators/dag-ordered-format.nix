{ lib, pkgs, ... }:

let
  orderedJsonFormat = lib.hm.generators.mkDAGOrderedJsonFormat { inherit pkgs; };
  # YAML and TOML use the same DAG-ordered JSON renderer, then convert with
  # remarshal. Keep them disabled in NMT for now because remarshal in
  # nativeBuildInputs pulls a real Python closure through the scrubbed pkgs set.
  # orderedYamlFormat = lib.hm.generators.mkDAGOrderedYamlFormat { inherit pkgs; };
  # orderedTomlFormat = lib.hm.generators.mkDAGOrderedTomlFormat { inherit pkgs; };
  orderedIniFormat = lib.hm.generators.mkDAGOrderedIniFormat { inherit pkgs; };
  orderedKeyValueFormat = lib.hm.generators.mkDAGOrderedKeyValueFormat { inherit pkgs; };

  # This looks like a DAG entry, but should be rendered as plain data.
  plainDagEntryShape = {
    data.keep = true;
    after = [ ];
    before = [ ];
  };

  orderedFormatData = {
    ordered = {
      after = lib.hm.dag.entryAfter [ "before" "plainDagEntryShape" ] {
        nested = {
          after = lib.hm.dag.entryAfter [ "before" ] 2;
          before = 1;
        };
      };

      before = "ask";
      inherit plainDagEntryShape;
    };
  };
in
{
  home.file = {
    "dag-ordered-attrs.txt".text =
      lib.concatMapStringsSep "\n" (entry: "${entry.name}=${entry.value}") (
        lib.hm.generators.toDAGOrderedAttrs { } {
          after = lib.hm.dag.entryAfter [ "before" ] "2";
          before = "1";
        }
      )
      + "\n";

    "dag-ordered-format.json".source =
      orderedJsonFormat.generate "dag-ordered-format.json" orderedFormatData;

    # "dag-ordered-format.yaml".source =
    #   orderedYamlFormat.generate "dag-ordered-format.yaml" orderedFormatData;
    #
    # "dag-ordered-format.toml".source =
    #   orderedTomlFormat.generate "dag-ordered-format.toml" orderedFormatData;

    "dag-ordered-format.ini".source = orderedIniFormat.generate "dag-ordered-format.ini" {
      aa = lib.hm.dag.entryAfter [ "zz" ] {
        bb = lib.hm.dag.entryAfter [ "cc" ] "2";
        cc = "1";
      };

      zz = {
        value = "ask";
      };
    };

    "dag-ordered-key-value.conf".source = orderedKeyValueFormat.generate "dag-ordered-key-value.conf" {
      aa = lib.hm.dag.entryAfter [ "zz" ] "2";
      zz = "1";
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/dag-ordered-attrs.txt \
      ${./dag-ordered-attrs.txt}

    assertFileContent \
      home-files/dag-ordered-format.json \
      ${./dag-ordered-format.json}

    # assertFileContent \
    #   home-files/dag-ordered-format.yaml \
    #   ${./dag-ordered-format.yaml}
    #
    # assertFileContent \
    #   home-files/dag-ordered-format.toml \
    #   ${./dag-ordered-format.toml}

    assertFileContent \
      home-files/dag-ordered-format.ini \
      ${./dag-ordered-format.ini}

    assertFileContent \
      home-files/dag-ordered-key-value.conf \
      ${./dag-ordered-key-value.conf}
  '';
}
