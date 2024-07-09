local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local model = require('periscope.model')
local conf = require('telescope.config').values
-- Custom sorter function
local function usage_sorter()
	return sorters.Sorter:new {
		scoring_function = function(_, prompt, ordinal, entry)
			return entry.value.usage
		end,
	}
end

local function show_files_for_current_task()
	local task = model.get_current_task()
	if not task then
		print("No current task")
		return
	end
	local opts = {}
	pickers.new(opts, {
		prompt_title = "Task" .. task.name .. " files",
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
		sorter = usage_sorter(),
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
	local tasks = model.get_all_tasks()
	local opts = {}
	pickers.new(opts, {
		prompt_title = "All tasks ol29",
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
		sorter = conf.generic_sorter(opts),
		--sorter = usage_sorter(),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				model.set_current_task(selection.value.id)
				print("Current task set to: " .. selection.value.name)
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
