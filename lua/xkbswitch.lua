local M = {}
-- nvim_create_autocmd shortcut
local autocmd = vim.api.nvim_create_autocmd

local xkb_switch_lib = nil
local xkb_switch_app = nil
local user_os_name = vim.loop.os_uname().sysname

-- Find the path to the xkbswitch shared object (macOS)
if user_os_name == 'Darwin' then
    local app = vim.fn.system('which issw')
    if app then
        xkb_switch_app = 'issw'
    end
    if vim.fn.filereadable('/usr/local/lib/libInputSourceSwitcher.dylib') then xkb_switch_lib = '/usr/local/lib/libInputSourceSwitcher.dylib'
    elseif vim.fn.filereadable('/usr/lib/libInputSourceSwitcher.dylib') then xkb_switch_lib = '/usr/lib/libInputSourceSwitcher.dylib' end
-- Find the path to the xkbswitch shared object (Linux)
else
    local app = vim.fn.system('which xkb-switch')
    if app then
        xkb_switch_app = 'xkb-switch'
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
    app = vim.fn.system('which g3kb-switch')
    if app then
        xkb_switch_app = 'g3kb-switch'
        if vim.fn.filereadable('/usr/local/lib/libg3kbswitch.so') then xkb_switch_lib = '/usr/local/lib/libg3kbswitch.so' end
    end
end

if xkb_switch_lib == nil then
    error("(xkbswitch.lua) Error occured: libxkbswitch.so.1 / libInputSourceSwitcher.dylib / libg3kbswitch.so was not found.")
end

if xkb_switch_app == nil then
    error("(xkbswitch.lua) Error occured: xkb-switch / issw / g3kb-switch was not found.")
end


local function get_current_layout()
    return vim.fn.libcall(xkb_switch_lib, 'Xkb_Switch_getXkbLayout', '')
end

local saved_layout = get_current_layout()
local user_us_layout_variation = nil

local user_layouts = vim.fn.systemlist(xkb_switch_app .. " -l")
-- Find the used US layout (us/us(qwerty)/us(dvorak)/...)
for _, value in ipairs(user_layouts) do
    if string.find(value, user_os_name == 'Darwin' and 'ABC' or '^us') then
        user_us_layout_variation = value
    end
end

if user_us_layout_variation == nil then
    error("(xkbswitch.lua) Error occured: could not find the English layout. Check your layout list. (" .. xkb_switch_app .. " -l)")
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
