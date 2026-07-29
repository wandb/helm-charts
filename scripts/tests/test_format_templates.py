import unittest

from scripts.format_templates import format_source


class FormatTemplatesTest(unittest.TestCase):
    def test_preserves_structured_comments_while_applying_outer_indentation(
        self,
    ) -> None:
        source = """{{- define "example" -}}
{{- /*
  config:
    nested: true

 */ -}}
{{- end -}}
"""

        def indent_nested_comment(masked_source: str) -> str:
            return (
                "\n".join(
                    (
                        f"  {line.lstrip()}"
                        if "HELMFMT_PRESERVE_COMMENT_" in line
                        else line
                    )
                    for line in masked_source.splitlines()
                )
                + "\n"
            )

        formatted = format_source(source, indent_nested_comment)

        self.assertEqual(
            formatted,
            """{{- define "example" -}}
  {{- /*
    config:
      nested: true

  */ -}}
{{- end -}}
""",
        )
        self.assertFalse(any(line.endswith(" ") for line in formatted.splitlines()))
        self.assertEqual(format_source(formatted, indent_nested_comment), formatted)


if __name__ == "__main__":
    unittest.main()
