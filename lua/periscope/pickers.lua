local utils = require('periscope.utils')
local fzf_lua = require("fzf-lua")
local function nvim_tree()
	return require('periscope.nvim-tree')
end
function model()
	return require('periscope.model')
end

local conf = require('telescope.config').values
-- Custom sorter function
local function file_sorter()
	return sorters.Sorter:new {
		scoring_function = function(_, prompt, ordinal, entry)
			-- Sort by usage
			local last_file = model().get_current_workspace().last_file or "no_last_file"
			print("last_file ", prompt, ordinal, entry.value.path, last_file)
			if entry.value.path == last_file then
				return 9999999999999
			end
			return -entry.value.usage
		end,
	}
end




local function show_files_for_current_task(fullpath)
    model().remove_deleted_files_from_current_tasks()
    local task = model().get_current_task()

    if not task then
        print("No current task")
        return
    end

    -- Sort files by usage (descending)
    table.sort(task.files, function(a, b)
        return (a.usage or 0) > (b.usage or 0)
    end)

    -- Prepare the list of files for fzf
    local file_list = {}
    for _, file in ipairs(task.files) do
        local display_name = fullpath and file.path or vim.fn.fnamemodify(file.path, ":t")
        table.insert(file_list, string.format("%s [Usage: %d]", display_name,  file.usage or 0))
    end

    -- Use fzf-lua with exact matching and pre-sorted files
    fzf_lua.fzf_exec(file_list, {
        prompt = task.name .. ": files> ",
        fzf_opts = {
            ["--exact"] = "", -- Enables exact substring matching
            ["--tiebreak"] = "index", -- Ensure sorting respects the input order (pre-sorted by usage)
        },
        actions = {
            ["default"] = function(selected)
                -- Extract the file path from the selected item
                local selected_entry = selected[1]
                for _, file in ipairs(task.files) do
                    local display_name = fullpath and file.path or vim.fn.fnamemodify(file.path, ":t")
                    if selected_entry:find(display_name, 1, true) then
                        -- Open the selected file
                        local path = utils.to_absolute_path(file.path)
                        vim.cmd("edit " .. path)
                        return
                    end
                end
            end,
        },
    })
end




--local fzf_lua = require("fzf-lua")



local function show_all_tasks()
    local current_task_name = model().get_current_task_name() or "No task selected"
    local tasks = model().get_all_tasks()

    -- Sort tasks by usage (descending)
    table.sort(tasks, function(a, b)
        return (a.usage or 0) > (b.usage or 0)
    end)

    -- Prepare the list of tasks for fzf
    local task_list = {}
    for _, task in ipairs(tasks) do
        local prefix = (task.name == current_task_name) and "[CURRENT] " or ""
        table.insert(task_list, string.format("%s%s (Usage: %d)", prefix, task.name, task.usage or 0))
    end

    -- Use fzf-lua with exact matching and pre-sorted tasks
    fzf_lua.fzf_exec(task_list, {
        prompt = "All tasks (current: " .. current_task_name .. ")> ",
        fzf_opts = {
            ["--exact"] = "", -- Enables exact substring matching
            ["--tiebreak"] = "index", -- Ensure sorting respects the input order (pre-sorted by usage)
        },
        actions = {
            ["default"] = function(selected)
                -- Extract the task name (remove prefix and usage information)
                local selected_name = selected[1]:match("%[CURRENT%]%s*(.-)%s%(%w+.-%)") or
                                      selected[1]:match("^(.-)%s%(%w+.-%)")

                -- Find the selected task by name
                for _, task in ipairs(tasks) do
                    if task.name == selected_name then
                        -- Set the selected task as the current task
                        model().set_current_task(task.id)
                        nvim_tree().set_filter_enabled(true)
                        print("Task set to: " .. task.name)
                        return
                    end
                end
            end,
        },
    })
end
return {
	show_files_for_current_task = show_files_for_current_task,
	show_all_tasks = show_all_tasks,

}
