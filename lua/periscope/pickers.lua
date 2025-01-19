local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local utils = require('periscope.utils')
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
			if entry.value.path == last_file then
				return 9999999999999
			end
			return -entry.value.usage
		end,
	}
end

local function show_files_for_current_task_(fullpath)
	model().remove_deleted_files_from_current_tasks()
	local task = model().get_current_task()
	if not task then
		print("No current task")
		return
	end
	local opts = {
		filter_function = function(entry)
			local prompt = vim.fn.input("Enter exact match filter: ")
			return entry.path:find(prompt, 1, true) ~= nil
		end
	}
	local function get_show_name(path)
		if fullpath then
			return path
		else
			return vim.fn.fnamemodify(path, ":t")
		end
	end
	pickers.new(opts, {

		prompt_title = task.name .. ": files",
		finder = finders.new_table {
			results = task.files,
			entry_maker = function(entry)
				local file_id = entry.file_id or "no_file_id";
				local display_name = get_show_name(entry.path).." ("..file_id..")"
				return {
					value = entry,
					display = display_name,
					ordinal = display_name,
				}
			end,
		},
		sorter = file_sorter(),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				local path = utils.to_absolute_path(selection.value.path)
				vim.cmd("edit " .. path)
			end)
			return true
		end,
	}):find()
end

local function show_files_for_current_task(fullpath)
	model().remove_deleted_files_from_current_tasks()
	local task = model().get_current_task()
	if not task then
		print("No current task")
		return
	end

	local opts = {}

	-- Helper to get the display name
	local function get_show_name(path)
		if fullpath then
			return path
		else
			return vim.fn.fnamemodify(path, ":t")
		end
	end

	-- Custom finder that filters for exact matches
	local function custom_finder(search)
		return finders.new_table {
			results = vim.tbl_filter(function(file)
				-- Filter by exact match of the search string in the filename
				return vim.fn.fnamemodify(file.path, ":t"):find(search, 1, true) ~= nil
			end, task.files),
			entry_maker = function(entry)
				local file_id = entry.file_id or "no_file_id"
				return {
					value = entry,
					display = get_show_name(entry.path) .. " (" .. file_id .. ")",
					ordinal = entry.path, -- Use the full path for sorting
				}
			end,
		}
	end

	-- Custom sorter that sorts by `file.usage`
	local function custom_sorter()
		return sorters.Sorter:new {
			scoring_function = function(_, _, _, entry1, entry2)
				local usage1 = entry1.value.usage or 0
				local usage2 = entry2.value.usage or 0
				return usage1 > usage2 and -1 or (usage1 < usage2 and 1 or 0)
			end,
		}
	end

	-- Prompt for search term
	vim.ui.input({ prompt = "Search filename: " }, function(search)
		if not search or search == "" then
			print("No search term provided")
			return
		end

		pickers.new(opts, {
			prompt_title = task.name .. ": files",
			finder = custom_finder(search),
			sorter = custom_sorter(),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					local path = utils.to_absolute_path(selection.value.path)
					vim.cmd("edit " .. path)
				end)
				return true
			end,
		}):find()
	end)
end

local function show_all_tasks()
	local current_task_name = model().get_current_task_name() or "No task selected";
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
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				model().set_current_task(selection.value.id)
				nvim_tree().set_filter_enabled(true)
			end)
			return true
		end,
	}):find()
end
return {
	show_files_for_current_task = show_files_for_current_task,
	show_all_tasks = show_all_tasks,

}
