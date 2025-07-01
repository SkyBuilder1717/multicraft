## UC-signs
The ultra cool signs mod uses unicode_text and tga_encoder to add unicode support to signs without the need for texture files per character.

Note about support of connecting and non-LTR scripts:
Connecting features seem to sometimes work while RL-TB does not work at all currently and Top-to-Bottom(vertical writing systems) seem to have issues as well.
If you can read any of these scripts any help would be appreciated although probably best at https://git.minetest.land/erlehmann/unicode_text which is the rendering engine used here.

Other than the "classic" method of having multiple textures that each represent one character and which are then stitched together by texture modifiers, this uses unicode_text and tga_encoder to create a texture for each sign using a (hex-)font. The texture is then stored in the node meta of the sign alongside of the text so the texture can be regenerated if needed.

The main upside of this approach is the support of many different scripts, symbols emojis etc. (all of unifont + some of unifont csur).

Depends:
* https://git.minetest.land/erlehmann/tga_encoder
* https://git.minetest.land/erlehmann/unicode_text

![](https://mister-muffin.de/p/7WyA.png)
UC signs can show characters the builtin minetest font can't!

Supports unified dyes and mcl_dyes for coloring signs (rightclick sign with dye)

Confirmed to work out of the box with the following games:
* Minetest Game
* Mineclonia (until the shipped tga_encoder is updated, you need to force load the most recent version)
* MineClone2 (until the shipped tga_encoder is updated, you need to force load the most recent version)
* Repixture
* Xaenvironment
* Lord of the Test
* MeseCraft
* Asuna

Should generally work out of the box with all games that define nodes with the itemgroup wood (craft recipe also needs an item of group:stick).

For all other games you will need to supply your own sign registration where you need to at least define the desired color of your sign - see API.md for how to do that.

### Credits
All textures and model files are from mineclonia / mineclone2 mcl_signs.

### Fonts used
* unifont https://unifoundry.com/unifont/index.html
* unifont csur planes 00 and 0f from https://github.com/trevorld/hexfont

## Code License
AGPL 3.0 - https://www.gnu.org/licenses/agpl-3.0.txt

## Media License
CC-BY-SA 4.0 - https://creativecommons.org/licenses/by-sa/4.0/
