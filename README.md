behatdoccer
===========

A script that generates a doc of the behat steps and scenarios written in Ruby - why? why not.

The script goes through all feature and step files and generates and HTML document with two main sections.

The first section contains a list of all the steps, for each step the script include the code location as well as the function use to implement it. In addition a link is provided that lists all scenarios where a step is used.

The second section contains a list of all scenarios used in a suite. For each scenario all the tags applied to this scenario are specified.

The generated html document relies on a few js and css files which are included with the code.

Usage: behatparser.rb [options]
    -i, --input inputpath            Path to features folder
    -o, --output outputfile          Name of the output file
    -h, --help                       Display this screen
	
Example: ruby behatparser.rb -i c:\bdds\features -o out.html
	
It is assumed that the output file will reside in the same directory as the script in order to grab the included js and css.