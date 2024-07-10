local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local function nvim_tree()
	return require('periscope.nvim-tree')
end
function model()
	return require('periscope.model')
end

local conf = require('telescope.config').values
-- Custom sorter function
local function file_sorter()
	local default_sorter = conf.generic_sorter({})
	return sorters.Sorter:new {
		scoring_function = function(_, prompt, ordinal, entry)
			--when no prompt, sort by usage
			if prompt == "" then
				local last_file = model().get_current_workspace().last_file or "no_last_file"
				if entry.value.path == last_file then
					return 9999999999999
				end
				return -entry.value.usage
			else
				--else use default sorter
				return default_sorter:scoring_function(prompt, ordinal, entry)
			end
		end,

	}
end

-- and attemp to sort by string, will change..
local function get_string_numeric_value(str)
	local str = str:lower()
	local value = 0
	local factor = 1
	for i = 1, #str do
		value = value + string.byte(str, i) * factor
		factor = factor * 256
	end
	return value
end
local function task_sorter()
	return sorters.Sorter:new {
		scoring_function = function(_, prompt, ordinal, entry)
			return get_string_numeric_value(entry.value.name)
		end,
	}
end


local function show_files_for_current_task()
	model().remove_deleted_files_from_current_tasks()
	local task = model().get_current_task()
	if not task then
		print("No current task")
		return
	end
	local opts = {}
	pickers.new(opts, {
		prompt_title = task.name .. ": files",
		finder = finders.new_table {
			results = task.files,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.path,
					ordinal = entry.path,
				}
			end,
		},
		sorter = file_sorter(),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				vim.cmd("edit " .. selection.value.path)
			end)
			return true
		end,
	}):find()
end
local function show_all_tasks()
	local current_task_name = model().get_current_task_name() or "No task selected";
	local current_task_id = model().get_current_task_id() or 999;
	local opts = {}
	local tasks = model().get_all_tasks()
	pickers.new(opts, {
		prompt_title = "All tasks (current: " .. current_task_name .. ")",
		finder = finders.new_table {
			results = tasks,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.name,
					ordinal = entry.name,
				}
			end,
		},
		strategy = "ascending",
		sorter = task_sorter(),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				model().set_current_task(selection.value.id)
				nvim_tree().filter_tree()
			end)
			return true
		end,
	}):find()
end
return {
	show_files_for_current_task = show_files_for_current_task,
	show_all_tasks = show_all_tasks,

}
