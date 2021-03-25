# SwitchAudio
A simple AHK script that helps quickly changing the default audio output on windows.

## Keybinds
- `Shift + F[1-9]` : Set the n-th bound device as the default output.
- `F1 + F2`: List all bound devices and their asscociated keybinds
- `F1 + F3`: Change bindings

## Bindings
When first launching the script, or when pressing `F1 + F3`, a text file is created in your AppData/Roaming/SwitchAudio folder. It also shows a list of all avaliable devices.
To bind a device to the `Shift + F[N]` macro, add the name of the device (or a recognisable part of the name) to the N-th line of the file.
