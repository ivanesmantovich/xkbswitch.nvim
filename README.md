<div align="center">
  <p>
    <img src="assets/logo.png" align="center" alt="Logo" />
  </p>
</div>

Do you have more than one keyboard layout and constantly switching back to English just to be able to move?\
Stop it, get some help!\
With **xkbswitch.nvim** you can write comments/notes/documents in your language of choice, press `Esc` to enter Normal mode and instantly be ready to make your next move.\
Plugin saves your actual layout before switching to English. The next time you enter Insert mode you will have your last saved layout.\
**It also works with focus.** When Neovim loses focus plugin switches your layout to the last saved one. When Neovim gets focus plugin saves your layout, which you could've changed in another window and switches to English **only if** you need it. ([Logic](#about))\
Now you need to switch your layout only when you need to type something in a different language! That's the way it always should have been.

## macOS
1. Install [input-source-switcher](https://github.com/vovkasm/input-source-switcher)
```bash
git clone https://github.com/vovkasm/input-source-switcher.git
cd input-source-switcher
mkdir build && cd build
brew install cmake
cmake ..
make
sudo make install
```

2. Install this plugin
<table>
<tr>
  <th> Packer </th>
  <th> Lazy (~/.config/nvim/lua/plugins/xkbswitch.lua) </th>
  <th> Dein </th>
</tr>
<tr>
<td>

```
use 'ivanesmantovich/xkbswitch.nvim'
```

</td>
<td>

```
return { 
    {'ivanesmantovich/xkbswitch.nvim'} 
}
```

</td>
<td>

```
call dein#add('ivanesmantovich/xkbswitch.nvim')
```

</td>
</tr>
</table>

3. Add the setup line to your config
```
require('xkbswitch').setup()
```

## Linux / Unix (X.org / Wayland)
1. Install package `libxkbfile-dev` (or `libxkbfile-devel` if you use Fedora)
2. Install [xkb-switch](https://github.com/grwlf/xkb-switch)
```bash
git clone https://github.com/grwlf/xkb-switch.git
cd xkb-switch
mkdir build && cd build
cmake ..
make
sudo make install
sudo ldconfig
```
3. Install this plugin
<table>
<tr>
  <th> Packer </th>
  <th> Lazy (~/.config/nvim/lua/plugins/xkbswitch.lua) </th>
  <th> Dein </th>
</tr>
<tr>
<td>

```
use 'ivanesmantovich/xkbswitch.nvim'
```

</td>
<td>

```
return { 
    {'ivanesmantovich/xkbswitch.nvim'} 
}
```

</td>
<td>

```
call dein#add('ivanesmantovich/xkbswitch.nvim')
```

</td>
</tr>
</table>

4. Add the setup line to your config
```
require('xkbswitch').setup()
```

## GNOME 3 or 4 (g3kb-switch)
1. Install `libglib2.0-dev` package (or `glib2-devel` if you use Fedora)
2. Install [g3kb-switch](https://github.com/lyokha/g3kb-switch) and the [extension](https://github.com/lyokha/g3kb-switch#gnome-41-and-newer).
```bash
git clone https://github.com/lyokha/g3kb-switch.git
cd g3kb-switch
mkdir build && cd build
cmake ..
make
sudo make install

cd ../extension
make install  # no sudo required!
```
3. Install this plugin
<table>
<tr>
  <th> Packer </th>
  <th> Lazy (~/.config/nvim/lua/plugins/xkbswitch.lua) </th>
  <th> Dein </th>
</tr>
<tr>
<td>

```
use 'ivanesmantovich/xkbswitch.nvim'
```

</td>
<td>

```
return { 
    {'ivanesmantovich/xkbswitch.nvim'} 
}
```

</td>
<td>

```
call dein#add('ivanesmantovich/xkbswitch.nvim')
```

</td>
</tr>
</table>

4. Add the setup line to your config
```
require('xkbswitch').setup()
```

## With Tmux
If you use Neovim inside of Tmux add this line to your `.tmux.conf`
```
set -g focus-events on
```

## About
This plugin uses autocommands to 'listen' when you are entering and exiting Insert mode, or when Neovim gets or loses focus, and libcalls to change your layout.

* **When leaving Insert Mode:**
1) Save the current layout
2) Switch to the US layout

* **When entering Insert Mode:**
1. Switch to the previously saved layout

* **When Neovim gets focus:**
1. Save the current layout
2. Switch to the US layout if Normal Mode or Visual Mode is the current mode

* **When Neovim loses focus:**
1. Switch to the previously saved layout
