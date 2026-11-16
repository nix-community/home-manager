{
  programs.gram = {
    enable = true;

    snippets = {
      global = { };
      jsx = { };
      plain = { };
    };
  };

  test.asserts.assertions.expected =
    let
      mkExpectedAssertion = scope: substitute: ''
        The snippet scope defined at `programs.gram.snippets.${scope}` is incorrect,
        use `programs.gram.snippets.${substitute}` instead.

        (reasoning: <https://gram-editor.com/docs/snippets/>)
      '';
    in
    [
      (mkExpectedAssertion "global" "snippets")
      (mkExpectedAssertion "jsx" "javascript")
      (mkExpectedAssertion "plain" "plaintext")
    ];
}
