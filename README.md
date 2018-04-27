# Technical Accuracy Tests

## What it is

This is a test for [Emender](https://github.com/emender/emender) framework. It checks all the links in documentation and analyzes their behavior. For example, it reports non-functional or blacklisted external links.

## How to run it
To run the test locally, follow these steps.
1. Download the repository to your local machine. You don't need to have the test and documentation in the same folder. In fact, it's advisable not to.
2. Download the documentation files into a separate folder. This folder must include:
	* publican.cfg
		* config file for your documentation, should have a "mainfile" parameter with the name of the master file, e.g. "mainfile: master", otherwise the script will use default master filename ("master").
    * master file 
        * located in the "your_language/" subfolder, e.g. "en-US/"
3. Before running the test make sure to install dependencies: curl and wget (usually included in Linux distributions, but just in case).	
~~~~~~~~
sudo dnf install curl
sudo dnf install wget
~~~~~~~~ 
4. You'll also need Lua installed.
~~~~~~~~
sudo dnf install lua
~~~~~~~~
5. Last piece is libraries. These can be downloaded [here](https://github.com/emender/emender-lib/tree/master/lib). You need "publican.lua" and "xml.lua". When you first run the test, it will give you an error message and you'll see the path at which these libraries should be placed.
6. You're ready to run the test! Through Terminal navigate to the documentation folder. Then type `emend path_to_test_folder/TechnicalAccuracy.lua` and see the results. You can check available Emender parameters [here](https://github.com/emender/emender/blob/master/doc/man/man1/emend.1.pod).
7. You can additionally provide "blacklistedLinks" as a test parameter. For this, use `--XblacklistedLinks="link1, link2, link3,..."` when running the test. You can also check out "exampleList" and "internalList".

## License

*technical-accuracy-tests* is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation; version 3 of the License.

*technical-accuracy-tests* is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public
License](http://www.gnu.org/licenses/) for more details.

