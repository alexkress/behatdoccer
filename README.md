behatdoccer
===========

A script that generates a doc of the behat steps and scenarios written in Ruby - why? why not.

**Features:**

The script goes through all feature and step files and generates an HTML document with two main sections.

The first section contains a list of all the steps, for each step the script includes the code location as well as the function used to implement it. In addition a link is provided that lists all scenarios where a step is used.

The second section contains a list of all scenarios used in a suite. For each scenario all the tags applied to this scenario are specified.

The generated html document relies on a few js and css files which are included with the code.

**Usage:** behatparser.rb [options]
    -i, --input inputpath            Path to features folder
    -o, --output outputfile          Name of the output file
    -h, --help                       Display this screen
	
Example: ruby behatparser.rb -i c:\bdds\features -o out.html
	
It is assumed that the output file will reside in the same directory as the script in order to grab the included js and css.

**License:**

 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 
**Code quality:**

This script evolved over time. Ideally at this point it should be split up and cleaned up, but it works and will probably not get touched up until some more major changes are done.