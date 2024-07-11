local lume = require('periscope.lume')
local function model()
	return require('periscope.model')
end
local nvim_tree_api = require('nvim-tree.api')
local view = require('nvim-tree.view')
local utils = require('nvim-tree.utils')
local filter = require('nvim-tree.explorer.filters')
local nvim_tree_api = require('nvim-tree.api')
local tree = nvim_tree_api.tree

local filter = require('nvim-tree.explorer.filters')
local prev_filter_function = filter.custom_function
local enabled = false
--forward declarations
local set_filter_enabled, filter_tree, unfilter_tree

function set_filter_enabled(_enable)
	enabled = _enable
	if enabled then
		filter_tree()
	else
		unfilter_tree()
	end
end

function filter_tree()
	if enabled then
		filter.custom_function = function(file_or_dir)
			local current_task = model().get_current_task()
			if not current_task then
				return false
			end
			local task_files = lume.map(current_task.files, function(file)
				return vim.fn.fnamemodify(file.path, ":p")
			end)

			local path = vim.fn.fnamemodify(file_or_dir, ":p")

			-- Check if the path is in the task files
			if lume.find(task_files, path) then
				return false -- Do not exclude files in the task list
			end

			-- Check if the directory contains any task files
			for _, task_file in ipairs(task_files) do
				if vim.fn.isdirectory(path) == 1 and vim.startswith(task_file, path) then
					return false -- Do not exclude directories that contain task files
				end
			end

			return true -- Exclude everything else
		end
		--filter.custom_function = nil
		--tree.open()

		tree.expand_all()
		tree.reload() -- This applies the filter
	end
end

function unfilter_tree()
	filter.custom_function = nil --prev_filter_function
	tree.reload()
end

--local dir = vim.fn.getcwd();
--tree.open({ path = dir });
--filter_tree()
return {
	filter_tree = filter_tree,
	unfilter_tree = unfilter_tree,
	set_filter_enabled = set_filter_enabled
}
