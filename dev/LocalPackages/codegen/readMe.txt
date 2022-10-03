Generates a random code on demand!

Usage:

 Call _codegen(NUMBER, character type 1, character type 2) in your script.
 The number determines how long the code is, and the 2 types determine which types of characters you want. 
 Character types: lowercase ("lower"), uppercase ("upper"), number ("num"), symbol ('sym'), full (all alphanumeric characters) or all (Full + symbols).

/codegen = Prints a randomly generated code to you.


Permissions:
commandhelper.alias.codegen: Use /codegen

Notes:
- a Zero (0) is not present in the numbers to avoid confusion with the letter O.
- To avoid server crash on the main thread, the code generator is limited to a maximum of 512 characters. If the separate thread is used this limit is removed.

