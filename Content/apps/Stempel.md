---
app.masLink: https://apple.co/41U4L1a
app.appleID: 1638437641
app.mastodonLink: https://indieapps.space/@stempel
---

# Stempel
## Create New Files

Stempel is a native macOS app for creating new files in Finder.
Users can manage templates that they edit in Stempel or in in any other editor of their choice.
New files are created by right clicking in Finder or by adding an item to Finder’s toolbar.

![Screenshot|The right click menu in Finder showing the configured templates.](/apps/Stempel/right-click.png)

This is a natural behavior that users might expect as it is built into most other operating systems.
There even is a *New Folder* button in the right click menu in Finder.

![Screenshot|A screenshot of Stempel showing multiple templates in the sidebar while editing the template for a LaTeX Document.](/apps/Stempel/main.png)

Templates can be managed right in the app, the sidebar shows a list of templates and they can be edited in the simple editor right in the app.
However right clicking a template or using the *File* menu in the toolbar allows the user to open the file in their favorite editor like Sublime Text or Nova, or to reveal it in Finder.

![Screenshot|An example of a file that cannot be edited as plain text. Clicking on it will open Numbers.](/apps/Stempel/complex.png)

Stempel allows for editing of plain text files.
Other files receive an inline preview and can be edited with an external app.

![Screenshot|A template folder containing multiple files.](/apps/Stempel/folders.png)

Even folders can be used as templates.
This way complex projects like a website with ^html^, ^php^ and JavaScript files can be instantiated easily from a template.

![Screenshot|The file permissions editor. This allows for new files to be marked as executable.](/apps/Stempel/permissions.png)

One powerful feature offered by Stempel is to configure ^posix^ permissions for files.
Each file can be individually selected to be readable, executable, or writable for user, group, and world.
This is especially handy when creating templates for executable files such as scripting languages like Python.
Stempel allows for this configuration to occur via a graphical representation of the familiar `ls` output as a table.
Presets allow for a quick configuration of text and script files.
