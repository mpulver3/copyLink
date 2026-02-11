# copyLink
Creates a bookmark for each header 2/3/dropdown, then attaches a hyperlinked image to that bookmark.

### Project Overview
The goal of the project is to create a script that will go through all files in a project to automatically add the copyLink icon and functionality to headers.

Applies to:

* h2
* h3
* MadCapDropDown

### Workflow
Confirm any bookmarks are in front of the h3, h2, dropdownHotspot, or dropdownhead 
* Use the built in Find feature to search for instances of </a>MadCap:dropDownHotspot
* For each result, move the bookmark into the hotspot.
* Save all files updated

Run the script for the folder or file. It assumes the copy images are present (and in a standard location) and the folder is within "Content".

Script: copyHeader.ps1
* Prompt user for folder or file
* Confirm that the folder\\file exists
* Search each htm and html file within the folder (recursively opening sub folders)
* each time there is a header 2 or 3 or a dropdown, but no bookmark, insert a new bookmark
* the bookmark should be named incrementally, while resetting the count each file
* each time there is a header 2 or 3 or a dropdown, with a bookmark, but no copy icon, insert the copy icon, referencing the bookmark
