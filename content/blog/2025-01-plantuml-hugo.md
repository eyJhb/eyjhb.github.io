---
title: Adding PlantUML support to Hugo
description: Adding PlantUML support in Hugo using pre-processing in Python and Nix
date: "2025-01-10T10:00:00Z"
categories: hugo python ci preprocessing plantuml
author: eyJhb
draft: false
---

Having the ability to make diagrams is very useful when conveying complex information.
This can be done using programs such as PlantUML, which can create various types of diagrams and output them as e.g. PDF, SVG, PNG.
However, by default Hugo does not integrate with PlantUML.

The goal is to be able to write something as.

~~~plantuml
```plantuml
Alice -> Bob: test
```
~~~

And get the following output.

```plantuml
Alice -> Bob: test
```

The plan is to do some pre-processing in Python, which will output an SVG file, which can be embedded as raw HTML into the markdown files.
This is all done before the markdown files are converted into HTML.

# Pre-processing files with Python
A simple Python script was created, which will accepts "processing rules", that consists of a regular expression that should be found in markdown files, as well as a function which is called when a match is found with the input from the capture group.
The processing rules function will then return the text that the captured regular expression should be replaced with.
The full processing script can be found [here](https://github.com/eyJhb/eyjhb.github.io/blob/3c6477f3bd4e113f7f5dfdb43079f4371b2e4c22/scripts/preprocessor.py), which can extended further with multiple processing rules.
For PlantUML this is a simple regular expression written as `` ^```plantuml([^`]+)\n^``` ``, which then pipes the input to the `plantuml` binary, and returns the SVG out as HTML.

```python
def PlantUMLProcessing(input_text: str) -> str:
    plantuml_svg_raw = subprocess.run(
        ["plantuml", "-pipe", "-tsvg"],
        input=input_text,
        capture_output=True,
        text=True,
    ).stdout
    plantuml_svg = plantuml_svg_raw[plantuml_svg_raw.find("<svg") :]

    return f"{plantuml_svg}\n<!-- PLANTUML SOURCE:{input_text}-->\n"
```

However, Hugo does not support adding raw HTML in markdown files by default, and will not render it.
This can be solved by using shortcodes, which simply wraps around the HTML and outputs it.

Create a file at `layouts/shortcodes/rawhtml.html`, with the following content.

```html
<!-- raw html -->
{{.Inner}}
```

This will allow inserting raw HTML like so.

```html
{{</* rawhtml */>}}
<svg ... />
{{</* /rawhtml */>}}
```

The pre-processing script and the shortcodes can then be combined to insert PlantUML diagrams into the final HTML.
The pre-processing does however change the source files, which is not ideal.
This however is not a problem, if the pre-processing script is run as a step in the publishing step of the workflow.

```yaml
- name: pre-process markdown files
  run: apt update && apt install -y plantuml && find content -type f -name '*.md' | python scripts/preprocessor.py --overwrite
```

Instead, I have chosen to use Nix to build my website in a sandbox, where I run the pre-processing in a prepatch phase.
This means that the files are only modified in when building my website, and does not affect the source files.

# Building using Nix
To use nix for this, firstly packaging the Python pre-processor is needed. 
This can be done like so

```nix
{ pkgs ? import <nixpkgs> {}, ... }:

pkgs.writers.writePython3 "preprocessor" {
  flakeIgnore = [
    "E203" # whitespace before ':'
    "W503" # line break before binary operator
  ];
} ./scripts/preprocessor.py;
```

By default, `writers.writePython3` will run Flake8 on the file, to catch any basic things errors, where cosmetic errors can be ignored.
Next a derivation that outputs the built website can be made.

```nix
{ pkgs ? import <nixpkgs> {}, ... }:

pkgs.stdenvNoCC.mkDerivation {
  name = "eyjhb-hugo-website";

  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = with pkgs; [
    hugo
  ];

  buildPhase = ''
    hugo --minify --baseURL "eyjhb.dk" --destination public
  '';

  installPhase = ''
    mkdir $out
    cp -a public $out
  '';
}
```

Running this a `result` directory will be made, containing the entire website.
Running the pre-processor can be done in the `patchPhase` of the derivation, and will look something like:


```nix
{ pkgs ? import <nixpkgs> {}, ... }:

let
  pypreprocessor = pkgs.writers.writePython3 "preprocessor" {
    flakeIgnore = [
      "E203" # whitespace before ':'
      "W503" # line break before binary operator
    ];
  } ./scripts/preprocessor.py;
in pkgs.stdenvNoCC.mkDerivation {
  name = "eyjhb-hugo-website";

  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = with pkgs; [
    hugo
    plantuml
  ];

  patchPhase = ''
    find content -type f -name '*.md' | ${pypreprocessor} --overwrite
  '';

  buildPhase = ''
    hugo --minify --baseURL "eyjhb.dk" --destination public
  '';

  installPhase = ''
    mkdir $out
    cp -a public $out
  '';
}
```

And success! Using `nix-build` the website can now be generated, and the output will have the PlantUML diagrams as in-line SVGs.

# Other ways to implement PlantUML
While researching how to PlantUML to work using Hugo, I discovered two other ways to get PlantUML support.

*Implement in Hugo with Goldmark*:
There is an [issue](https://github.com/gohugoio/hugo/issues/8398) tracking PlantUML support, and it was implemented in a fork [here](https://github.com/gadams999/hugo/commit/2fc83fc58b642a8aa566cae152b360ad3c76575e).
However, the issue was closed as stale, and instead there is an open [issue](https://github.com/gohugoio/hugo/issues/7921) for custom renderes which would also solve the issue.

*Implement using Hugo shortcodes*:
Using Hugo shortcodes was implemented [here](https://paul.dugas.cc/post/plantuml-shortcode/), however, this embeds the image with a `src` that points to `http://www.plantuml.com/plantuml/img/...`, which is not ideal for a small fast-loading website.
Besides, it adds a dependency on the officially hosted PlantUML server to be running.
