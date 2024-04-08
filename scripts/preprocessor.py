from typing import Callable
import subprocess
import argparse
import sys
import re


def PlantUMLProcessing(input_text: str) -> str:
    plantuml_svg_raw = subprocess.run(
        ["plantuml", "-pipe", "-tsvg"],
        input=input_text,
        capture_output=True,
        text=True,
    ).stdout
    plantuml_svg = plantuml_svg_raw[plantuml_svg_raw.find("<svg"):]

    return f"{plantuml_svg}\n<!-- PLANTUML SOURCE:{input_text}-->\n"


class ProcessingRule:
    def __init__(
        self,
        re_rule: str,
        processing_func: Callable[[str], str],
        is_raw_html: bool = False,
    ):
        self.re_rule: re.Pattern = re.compile(re_rule)
        self.processing_func: Callable[[str], str] = processing_func
        self.is_raw_html: bool = is_raw_html


class MarkdownPreProcessor:
    def __init__(
        self,
        processing_rules: list[ProcessingRule],
        overwrite_file: bool = False,
    ):
        self._overwrite_file: bool = overwrite_file
        self._processing_rules: list[ProcessingRule] = processing_rules

    def process_file(self, filename: str):
        print(f"processing file {filename}")

        data = open(filename, "r").read()

        for processing_rule in self._processing_rules:
            for m in reversed(list(processing_rule.re_rule.finditer(data))):
                matchGroup = m.groups()[0]

                beforeText = data[:m.start()]
                afterText = data[m.end():]
                newContent = processing_rule.processing_func(matchGroup)

                if processing_rule.is_raw_html:
                    data = (
                        beforeText
                        + "{{< rawhtml >}}"
                        + newContent
                        + "{{< /rawhtml >}}"
                        + afterText
                    )
                else:
                    data = beforeText + newContent + afterText

        if self._overwrite_file:
            open(filename, "w").write(data)
        else:
            print(data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--overwrite", action=argparse.BooleanOptionalAction)
    args = parser.parse_args()

    mdp = MarkdownPreProcessor(
        processing_rules=[
            ProcessingRule(
                re_rule=r"```plantuml([^`]+)```",
                processing_func=PlantUMLProcessing,
                is_raw_html=True,
            )
        ],
        overwrite_file=args.overwrite,
    )

    if sys.stdin.isatty():
        print("nothing to do, please pipe filenames to stdin")
        exit()

    for line in sys.stdin:
        file_path = line.strip()
        mdp.process_file(file_path)
