# ZP-Language-Rebuilder
A tool to help upgrading Zoom Player's ".dialog" language files to new versions

It works by reading the English language dialog file and then tries to reconstruct the previous "dialog" file based on the English entries object-order within the file.

This means that by running this tool on a dialog file, the translated text is carried over, any untranslated text is copied from the English source and the resulting dialog file should be line-equivalent and completely aligned (the info listed in the output file matches the exact line-order from the English dialog file).

This processing should make it far easier to locate and translate only the new text, while giving you feedback on which objects were removed (no longer existing in the English file), if there were mismatches or missing objects and more.

Download here:
https://www.inmatrix.com/download/zplangbuilder100.zip
