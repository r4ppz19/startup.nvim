-- Define individual character art
local R = {
	"██████╗ ",
	"██╔══██╗",
	"██████╔╝",
	"██╔══██╗",
	"██║  ██║",
	"╚═╝  ╚═╝",
}

local F4 = {
	"██╗  ██╗",
	"██║  ██║",
	"███████║",
	"╚════██║",
	"     ██║",
	"     ╚═╝",
}

local P = {
	"██████╗ ",
	"██╔══██╗",
	"██████╔╝",
	"██╔═══╝ ",
	"██║     ",
	"╚═╝     ",
}

local Z = {
	"███████╗",
	"╚══███╔╝",
	"  ███╔╝ ",
	" ███╔╝  ",
	"███████╗",
	"╚══════╝",
}

-- Define the spacer between characters
local spacer = " "

-- Construct the intro_logo for "R4PPZ"
local intro_logo = {
	R[1] .. spacer .. F4[1] .. spacer .. P[1] .. spacer .. P[1] .. spacer .. Z[1],
	R[2] .. spacer .. F4[2] .. spacer .. P[2] .. spacer .. P[2] .. spacer .. Z[2],
	R[3] .. spacer .. F4[3] .. spacer .. P[3] .. spacer .. P[3] .. spacer .. Z[3],
	R[4] .. spacer .. F4[4] .. spacer .. P[4] .. spacer .. P[4] .. spacer .. Z[4],
	R[5] .. spacer .. F4[5] .. spacer .. P[5] .. spacer .. P[5] .. spacer .. Z[5],
	R[6] .. spacer .. F4[6] .. spacer .. P[6] .. spacer .. P[6] .. spacer .. Z[6],
}

local PLUGIN_NAME = "r4ppz"
local DEFAULT_COLOR = "#98c379"
local INTRO_LOGO_HEIGHT = #intro_logo
-- Calculate the exact width by measuring the first line of the logo
local INTRO_LOGO_WIDTH = vim.fn.strdisplaywidth(intro_logo[1])

local autocmd_group = vim.api.nvim_create_augroup(PLUGIN_NAME, {})
local highlight_ns_id = vim.api.nvim_create_namespace(PLUGIN_NAME)
local r4ppz_buff = -1

local function unlock_buf(buf)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
end

local function lock_buf(buf)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function draw_r4ppz(buf, logo_width, logo_height)
	local window = vim.fn.bufwinid(buf)
	local screen_width = vim.api.nvim_win_get_width(window)
	local screen_height = vim.api.nvim_win_get_height(window) - vim.opt.cmdheight:get()

	-- Ensure precise centering by making the calculation more accurate
	local start_col = math.max(0, math.floor((screen_width - logo_width) / 2))
	local start_row = math.max(0, math.floor((screen_height - logo_height) / 2))

	-- Clear buffer first
	unlock_buf(buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

	-- Create empty lines for vertical centering
	local top_space = {}
	for _ = 1, start_row do
		table.insert(top_space, "")
	end

	vim.api.nvim_buf_set_lines(buf, 0, 0, true, top_space)

	-- Create spaces for horizontal centering - use string.rep for more accurate spacing
	local col_offset = string.rep(" ", start_col)

	-- Add all lines at once
	local adjusted_logo = {}
	for _, line in ipairs(intro_logo) do
		table.insert(adjusted_logo, col_offset .. line)
	end

	-- Insert the logo at the calculated position
	vim.api.nvim_buf_set_lines(buf, start_row, start_row, true, adjusted_logo)

	lock_buf(buf)

	-- Apply highlight to the entire logo area
	vim.api.nvim_buf_set_extmark(buf, highlight_ns_id, start_row, 0, {
		end_row = start_row + INTRO_LOGO_HEIGHT,
		end_col = screen_width,
		hl_group = "Default",
	})
end

local function create_and_set_r4ppz_buf(default_buff)
	local r4ppz_buff = vim.api.nvim_create_buf("nobuflisted", "unlisted")
	vim.api.nvim_buf_set_name(r4ppz_buff, PLUGIN_NAME)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = r4ppz_buff })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = r4ppz_buff })
	vim.api.nvim_set_option_value("filetype", "r4ppz", { buf = r4ppz_buff })
	vim.api.nvim_set_option_value("swapfile", false, { buf = r4ppz_buff })

	-- Set the new r4ppz_buff as the current buffer.
	vim.api.nvim_set_current_buf(r4ppz_buff)

	-- Now, attempt to delete the original default_buff.
	-- It's no longer the current buffer. Check its validity again, as switching
	-- might have caused it to be wiped (e.g., due to bufhidden=wipe or other autocommands).
	if vim.api.nvim_buf_is_valid(default_buff) then
		-- As a safeguard, ensure we are not trying to delete the buffer we just made current.
		-- This should not happen if default_buff and r4ppz_buff are distinct.
		if default_buff ~= r4ppz_buff then
			vim.api.nvim_buf_delete(default_buff, { force = true })
		end
	end

	return r4ppz_buff
end

local function set_options()
	vim.opt_local.number = false -- disable line numbers
	vim.opt_local.relativenumber = false -- disable relative line numbers
	vim.opt_local.list = false -- disable displaying whitespace
	vim.opt_local.fillchars = { eob = " " } -- do not display "~" on each new line
	vim.opt_local.colorcolumn = "0" -- disable colorcolumn
end

local function redraw()
	unlock_buf(r4ppz_buff)
	vim.api.nvim_buf_set_lines(r4ppz_buff, 0, -1, true, {})
	lock_buf(r4ppz_buff)
	draw_r4ppz(r4ppz_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)
end

local function display_r4ppz(payload)
	local is_dir = vim.fn.isdirectory(payload.file) == 1

	local default_buff = vim.api.nvim_get_current_buf()
	local default_buff_name = vim.api.nvim_buf_get_name(default_buff)
	local default_buff_filetype = vim.api.nvim_get_option_value("filetype", { buf = default_buff })
	-- Also check against PLUGIN_NAME in case it was already set somehow
	if
		not is_dir
		and default_buff_name ~= ""
		and default_buff_filetype ~= PLUGIN_NAME
		and default_buff_filetype ~= "r4ppz"
	then
		return
	end

	r4ppz_buff = create_and_set_r4ppz_buf(default_buff)
	set_options()

	draw_r4ppz(r4ppz_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)

	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = autocmd_group,
		buffer = r4ppz_buff,
		callback = redraw,
	})
end

-- Setup keybindings for the splash screen
local function setup_keymaps()
	local function close_splash()
		if vim.api.nvim_buf_is_valid(r4ppz_buff) then
			vim.api.nvim_buf_delete(r4ppz_buff, { force = true })
		end
	end

	-- Map 'q', 'Esc', and 'Enter' to close the splash screen
	vim.api.nvim_buf_set_keymap(r4ppz_buff, "n", "q", "", { callback = close_splash, noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		r4ppz_buff,
		"n",
		"<Esc>",
		"",
		{ callback = close_splash, noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(r4ppz_buff, "n", "<CR>", "", { callback = close_splash, noremap = true, silent = true })
end

local function setup(options)
	options = options or {}

	-- Set up highlight color
	local fg_color = options.color or DEFAULT_COLOR
	local bg_color = options.background or "NONE"

	vim.api.nvim_set_hl(highlight_ns_id, "Default", {
		fg = fg_color,
		bg = bg_color,
		bold = options.bold ~= nil and options.bold or false,
	})
	vim.api.nvim_set_hl_ns(highlight_ns_id)

	vim.api.nvim_create_autocmd("VimEnter", {
		group = autocmd_group,
		callback = function(payload)
			display_r4ppz(payload)
			setup_keymaps()
		end,
		once = true,
	})
end

return {
	setup = setup,
}
