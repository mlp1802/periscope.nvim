local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
function model()
	return require('periscope.model')
end

local conf = require('telescope.config').values
-- Custom sorter function
local function file_sorter()
	return sorters.Sorter:new {
		scoring_function = function(_, prompt, ordinal, entry)
			local last_file = model().get_current_workspace().last_file or "no_last_file"
			--print("last_file: " .. last_file .. "," .. entry.value.path)
			if entry.value.path == last_file then
				return 9999999999999
			end
			return -entry.value.usage
		end,
	}
end
local function get_string_numeric_value(str)
	--return value
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
		--sorter = conf.generic_sorter(opts),
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
	--print("NUMBER OF Tasks: " .. #tasks)
	local current_task_name = model().get_current_task_name() or "(No task selected)";

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
		--sorter = conf.generic_sorter(opts),
		--sorter = sorters.get_fuzzy_file(),
		--sorting_strategy = "ascending",
		sorter = task_sorter(),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				model().set_current_task(selection.value.id)
			end)
			return true
		end,
	}):find()
end

--model.create_task("SKOD 1");
--model.create_task("SKOD 2");
--show_all_tasks();
--model.add_file_to_current_task("test.lua")
--show_files_for_current_task()

return {
	show_files_for_current_task = show_files_for_current_task,
	show_all_tasks = show_all_tasks,

}
