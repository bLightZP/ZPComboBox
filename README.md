# ZPComboBox
A fast alternative to TComboBox

The standard Delphi TComboBox is based on WinAPI. Every item you add to the list triggers a WinAPI "SendMessage" call, which takes much (x100) longer than adding an item to a TStringList.

Since Zoom Player's options dialog contains so many TComboBox components, the commulative performance hit caused a serious delay when trying to show the form.

To overcome this delay, I wrote a slimmed down replica of TComboBox based on TStringList.

## Limitations
* The only event supported is OnChange.
* The only style supported is csDropDownList.
* The pop-up listbox is shown in a pop-up window, so the underlying window's title bar changes color when losing focus.
* The styling is close to TComboBox, but not identical.

## Note
I used the TNT unicode library to support Unicode under Delphi 7.
With newer version of Delphi, you can just remove the "TNT" as the components are drop-in replacements.
