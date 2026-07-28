# Working agreements

Run `python3 scripts/format_templates.py`, then run
`python3 -m unittest discover -s scripts/tests` and
`python3 scripts/check_template_maintainability.py` before considering template
changes complete. Use the `helmfmt` version pinned in `.github/workflows/lint.yaml`.
Also run the relevant chart lint and snapshot tests. Treat these checks as a
minimum: render the affected paths and understand the values, helpers, and
Kubernetes objects involved.

Keep template decisions easy to follow in source:

- Use `if`/`else` for complementary conditions instead of two adjacent `if`
  blocks.
- Indent nested template control flow to expose its structure, even when
  whitespace trimming means indentation does not affect rendered YAML.
- Prefer declarative values and focused helpers over repeated branch logic.
- Give compound conditions a name when that name communicates intent better
  than the inline expression.
- Exercise every meaningful branch with render or snapshot tests.

When an exception is necessary, keep it narrow and make the reason durable with
a focused behavior test or a concise comment next to the exception.
