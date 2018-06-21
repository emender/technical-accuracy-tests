# Technical Accuracy Tests

## What it is

This is a test for [Emender](https://github.com/emender/emender) framework. It checks all the links in documentation and analyzes their behavior. For example, it reports non-functional or blacklisted external links.

## How to run it
To run the test locally, follow these steps.
1. Download the repository to your local machine. You don't need to have the test and documentation in the same folder. In fact, it's advisable not to.
2. Download Emender framework [here](https://github.com/emender/emender).
3. Install Emender by navigating into the source code directory and running `sudo make install`.
4. Download documentation files into a separate folder. This folder must either include a publican.cfg file with documentation config (DocBook format) or master.adoc (AsciiDoc format).
5. Before running the tests, make sure to install these dependencies:
~~~~~~~~
sudo dnf install curl wget lua; gem install asciidoctor
~~~~~~~~
6. You're ready to run the test! Through command line navigate to the documentation folder (or the folder where you want to store the results). From this folder run the following command:
~~~~~~~~
PATH_TO_TEST_DIR/run.sh --XdocDir=PATH_TO_DOC_DIR
Only provide "docDir" argument if the documentation folder is different from the folder you're currently in.
~~~~~~~~
This will run a shell script that basically does all the dirty work before running the actual test. After running it you should see the test output on the screen, as well as a bunch of results.* files in the current folder. These files provide the results in various formats.
7. Add any extra parameters to Emender by using them as shell script arguments. Consult [this](https://github.com/emender/emender/blob/master/doc/man/man1/emend.1.pod) page for more info.
8. Add extra parameters to the test itself by using them as shell script arguments. Use this construct to do so: `--XparamName=paramValue`
You can, for example, add "blacklistedLinks", "exampleList" and "internalList" in this manner: `--XblacklistedLinks="link1, link2, link3, ..."`

## License

*technical-accuracy-tests* is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation; version 3 of the License.

*technical-accuracy-tests* is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public
License](http://www.gnu.org/licenses/) for more details.

