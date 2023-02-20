local M = {}
-- nvim_create_autocmd shortcut
local autocmd = vim.api.nvim_create_autocmd


local xkb_switch_lib = nil

-- Find the path to the xkbswitch shared object (macOS)
if vim.loop.os_uname().sysname == 'Darwin' then
  xkb_switch_lib = '/usr/local/lib/libInputSourceSwitcher.dylib'
end

-- Find the path to the xkbswitch shared object (Linux)
if xkb_switch_lib == nil then
    local all_libs_locations = vim.fn.systemlist('ldd $(which xkb-switch)')
    for _, value in ipairs(all_libs_locations) do
        if string.find(value, 'libxkbswitch.so.1') then
            if string.find(value, 'not found') then
                error("(xkbswitch.lua) Error occured: libxkbswitch.so.1 was not found.")
            else
                xkb_switch_lib = string.sub(
                    value, string.find(value, "/"), string.find(value, "%(") - 2
                )
            end
        end
    end
end

if xkb_switch_lib == nil then
    error("(xkbswitch.lua) Error occured: libxkbswitch.so.1 was not found.")
end


local function get_current_layout()
    return vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_getXkbLayout', '')
end

local saved_layout = get_current_layout()
local user_us_layout_variation = nil

local user_layouts = vim.fn.systemlist('xkb-switch -l')
-- Find the used US layout (us/us(qwerty)/us(dvorak)/...)
for _, value in ipairs(user_layouts) do
    if string.find(value, '^us') then
        user_us_layout_variation = value
    end
end

if user_us_layout_variation == nil then
    error("(xkbswitch.lua) Error occured: could not find the English layout. Check your layout list. (xkb-switch -l)")
end


function M.setup()
    -- When leaving insert mode:
    -- 1. Save the current layout
    -- 2. Switch to the US layout
    autocmd(
        'InsertLeave',
        {
            pattern = "*",
            callback = function ()
                vim.schedule(function()
                    saved_layout = get_current_layout()
                    vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', user_us_layout_variation)
                end)
            end
        }
    )

    -- When Neovim gets focus:
    -- 1. Save the current layout
    -- 2. Switch to the US layout if Normal mode or Visual mode is the current mode
    autocmd(
        'FocusGained',
        {
            pattern = "*",
            callback = function ()
                vim.schedule(function()
                    saved_layout = get_current_layout()
                    local current_mode = vim.api.nvim_get_mode().mode
                    if current_mode == "n" or current_mode == "no" or current_mode == "v" or current_mode == "V" or current_mode == "^V" then
                        vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', user_us_layout_variation)
                    end
                end)
            end
        }
    )

    -- When entering Insert mode:
    -- 1. Switch to the previously saved layout
    autocmd(
        'InsertEnter',
        {
            pattern = "*",
            callback = function ()
                vim.schedule(function()
                    vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', saved_layout)
                end)
            end
        }
    )

    -- When Neovim loses focus:
    -- 1. Switch to the previously saved layout
    autocmd(
        'FocusLost',
        {
            pattern = "*",
            callback = function ()
                vim.schedule(function()
                    vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', saved_layout)
                end)
            end
        }
    )
end


return M
