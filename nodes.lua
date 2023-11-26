--[[
    signs mod for Minetest - Various signs with text displayed on
    (c) Pierre-Yves Rollo

    This file is part of markdown_poster.

    signs is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    signs is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with signs.  If not, see <http://www.gnu.org/licenses/>.
--]]

local S = minetest.get_translator("markdown_poster")
local FS = function(...) return minetest.formspec_escape(S(...)) end

local function can_edit_poster(player, pos)
	if minetest.check_player_privs(player, "protection_bypass") then return true end

	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if node.name ~= "markdown_poster:poster" then return nil end

	if not owner or owner == "" or owner == player:get_player_name() then return true
	else return false end
end

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	local player = minetest.get_player_by_name(name)
	if player then
		local can_edit_poster = can_edit_poster(player, pos)
		if can_edit_poster ~= nil then return not can_edit_poster end
	end

	return old_is_protected(pos, name)
end

local function display_poster(pos, node, player)
	local meta = minetest.get_meta(pos)
	local font = font_api.get_font(meta:get_string("font"))
	local form_name = minetest.pos_to_string(pos) .. ":display"

	local titletexture = font:render(meta:get_string("display_text"),
		font:get_height() * 8.4, font:get_height(), {lines = 1, color = "#fff"})

	local formspec = string.format([[
		size[9,12]
		image[1,0;8.4,2;%s]
		%s ]],
		titletexture,
		md2f.md2f(0.3, 2, 9, 10.2, meta:get_string("text"))
	)

	if minetest.is_protected(pos, player:get_player_name()) then
		formspec = formspec .. string.format("button_exit[3.25,11;2.5,1.5;ok;%s]", FS("Close"))
	else
		formspec = formspec .. string.format("button[1,11;2.5,1.5;edit;%s]button_exit[5.5,11;2.5,1.5;ok;%s]",
			FS("Edit"), FS("Close")
		)
	end

	minetest.show_formspec(player:get_player_name(), form_name, formspec)
end

local function edit_poster(pos, meta, player)
	if not minetest.is_protected(pos, player:get_player_name()) then
		local form_name = minetest.pos_to_string(pos) .. ":edit"
		local formspec = string.format([[
			size[9, 10]
			field[0.5,0.7;8.5,1;display_text;%s;%s]
			textarea[0.5,1.7;8.5,8.5;text;%s;%s]
			button[1,9;2.5,1.5;font;%s]
			button_exit[5.5,9;2.5,1.5;write;%s] ]],
			FS("Title"), minetest.formspec_escape(meta:get_string("display_text")),
			FS("Text"), minetest.formspec_escape(meta:get_string("text")),
			FS("Title font"), FS("Write"))

		minetest.show_formspec(player:get_player_name(), form_name, formspec)
	end
end

minetest.register_on_player_receive_fields(function(player, form_name, fields)
	local pos = minetest.string_to_pos(form_name:match("[^:]+"))

	if pos then
		local node = minetest.get_node(pos)
		if node.name == "markdown_poster:poster" then
			local meta = minetest.get_meta(pos)

			if not minetest.is_protected(pos, player:get_player_name()) and fields then
				if form_name == minetest.pos_to_string(pos) .. ":display" and fields.edit then
					edit_poster(pos, meta, player)
				elseif form_name == minetest.pos_to_string(pos) .. ":edit" then
					if fields.font or fields.write or fields.key_enter then
						signs_api.set_display_text(pos, fields.display_text)
						meta:set_string("text", fields.text)
						meta:set_string("infotext", fields.display_text .. "\n" .. FS("(right-click to read more text)"))
					end
					if fields.write or fields.key_enter then
						display_poster(pos, node, player)
					elseif fields.font then
						font_api.show_font_list(player, pos)
					end
				end
			end
		end
	end
end)

signs_api.register_sign("markdown_poster", "poster", {
	depth = 1/32, width = 26/32, height = 30/32,
	entity_fields = {
		top = -11/32,
		size = { x = 26/32, y = 6/32 },
		maxlines = 1,
		color = "#000"
	},
	node_fields = {
		description = S("Markdown Poster"),
		tiles = {"signs_poster_sides.png", "signs_poster_sides.png",
				 "signs_poster_sides.png", "signs_poster_sides.png",
				 "signs_poster_sides.png", "signs_poster.png"},
		inventory_image = "signs_poster_inventory.png",
		groups = {dig_immediate = 3},

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", "")
		end,

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name())
		end,

		on_rightclick = display_poster
	}
})