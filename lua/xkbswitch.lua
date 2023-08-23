local M = {}
-- nvim_create_autocmd shortcut
local autocmd = vim.api.nvim_create_autocmd

local xkb_switch_lib = nil
local user_os_name = vim.loop.os_uname().sysname

-- Find the path to the xkbswitch shared object (macOS)
if user_os_name == 'Darwin' then
    if vim.fn.filereadable('/usr/local/lib/libInputSourceSwitcher.dylib') == 1 then
        xkb_switch_lib = '/usr/local/lib/libInputSourceSwitcher.dylib'
    elseif vim.fn.filereadable('/usr/lib/libInputSourceSwitcher.dylib') == 1 then
        xkb_switch_lib = '/usr/lib/libInputSourceSwitcher.dylib'
    end
    -- Find the path to the xkbswitch shared object (Linux)
else
    -- g3kb-switch
    if vim.fn.filereadable('/usr/local/lib64/libg3kbswitch.so') == 1 then
        xkb_switch_lib = '/usr/local/lib64/libg3kbswitch.so'
    elseif vim.fn.filereadable('/usr/local/lib/libg3kbswitch.so') == 1 then
        xkb_switch_lib = '/usr/local/lib/libg3kbswitch.so'
    else
        -- xkb-switch
        local all_libs_locations = vim.fn.systemlist('ldd $(which xkb-switch)')
        for _, value in ipairs(all_libs_locations) do
            if string.find(value, 'libxkbswitch.so.1') then
                if string.find(value, 'not found') then
                    xkb_switch_lib = nil
                else
                    xkb_switch_lib = string.sub(
                        value, string.find(value, "/"), string.find(value, "%(") - 2
                    )
                end
            end
        end
    end
end

if xkb_switch_lib == nil then
    error("(xkbswitch.lua) Error occured: layout switcher file was not found.")
end


local function get_current_layout()
    return vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_getXkbLayout', '')
end

local saved_layout = get_current_layout()
local user_us_layout_variation = nil

local user_layouts = vim.fn.systemlist(string.find(xkb_switch_lib, 'dylib') and 'issw -l' or
    string.find(xkb_switch_lib, 'xkb') and 'xkb-switch -l' or string.find(xkb_switch_lib, 'g3kb') and 'g3kb-switch -l')
-- Find the used US layout (us/us(qwerty)/us(dvorak)/...)
for _, value in ipairs(user_layouts) do
    if string.find(value, user_os_name == 'Darwin' and 'ABC' or '^us') then
        user_us_layout_variation = value
    elseif string.find(value, '.US$') then
        user_us_layout_variation = value
    end
end

if user_us_layout_variation == nil then
    error(
        "(xkbswitch.lua) Error occured: could not find the English layout. Check your layout list. (xkb-switch -l / issw -l / g3kb-switch -l)")
end

function M.setup()
    -- When leaving Insert Mode / Command Line:
    -- 1. Save the current layout
    -- 2. Switch to the US layout
    autocmd(
        {'InsertLeave', 'CmdlineLeave'},
        {
            pattern = "*",
            callback = function()
                vim.schedule(function()
                    saved_layout = get_current_layout()
                    vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', user_us_layout_variation)
                end)
            end
        }
    )

    -- When Neovim gets focus:
    -- 1. Save the current layout
    -- 2. Switch to the US layout if Normal Mode or Visual Mode is the current mode
    autocmd(
        'FocusGained',
        {
            pattern = "*",
            callback = function()
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

    -- When Neovim loses focus
    -- When entering Insert Mode / Command Line:
    -- 1. Switch to the previously saved layout
    autocmd(
        {'FocusLost', 'InsertEnter', 'CmdlineEnter'},
        {
            pattern = "*",
            callback = function()
                vim.schedule(function()
                    vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_setXkbLayout', saved_layout)
                end)
            end
        }
    )
end

return M
