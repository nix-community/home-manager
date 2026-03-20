{
  name = "pandoc-stub";
  outPath = null;
  buildScript = ''
    mkdir -p "$out"/bin
    pandoc="$out"/bin/pandoc
    echo 'Stub to make the wrapper happy' > "$pandoc"
    chmod a+x "$pandoc"
  '';
}
