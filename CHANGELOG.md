# Changelog

## 4.0.0

- Refactored script into a PowerShell module.
- Added Assets directory and moved appx removal definitions to text files to simplify function structure.
- Added a WorkingDirectory parameter and refactored all functions to use it as WimWitchFK no longer installs itself due to module conversions.

## 3.4.9

- Resolved wrong ascii character causing curly bracket imbalance on line 6991. Fix from @chadkerley
- Resolved issue with running wimwitch from command line. Fix from @THH-THC
- Resolved issue with update directories not being correctly parsed when processing updates.

## 3.4.8

- Added Windows 11 23H2 Appx removal list
- Added new Microsoft Backup tool to Appx removal list for Windows 11 23H2
- Resolved dotnet import version number issue

## 3.4.7

- Added support for Windows 11 23H2
