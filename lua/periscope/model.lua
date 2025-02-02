local lume = require('periscope.lume')
local nvim_tree = require('periscope.nvim-tree')
local lume_e = require('periscope.lume_extra')
local utils = require('periscope.utils')
local script = require('periscope.scripts')
local current_workspace = nil
local START_USAGE = 400
local START_TASK_USAGE = 400
local FILE_ID=0
--Forward declarations
local get_current_workspace, save_workspace, get_current_task, get_current_task_name, remove_deleted_files_from_current_tasks, new_task, buffer_entered, buffer_left, create_task, add_file_to_current_task, get_all_tasks, delete_current_task, get_current_task_id, rename_current_task, copy_current_task
file_ids = {}
local function get_file_id(path)
	if file_ids[path] == nil then
		FILE_ID = FILE_ID + 1
		file_ids[path] = FILE_ID
	end
	return file_ids[path]
end

local function new_file(path)
	return {
		file_id = get_file_id(path),
		path = path,
		usage = START_USAGE,
	}
end
-- creates a new workspace
function new_workspace()
	local workspace = {
		task_id = 0,
		current_task_id = 0,
		tasks = {},
		last_file = ""

	}
	return workspace
end

function get_project_directory()
	return vim.fn.getcwd() -- Gets the current working directory
end

function get_workspace_file_path()
	return get_project_directory() .. "/.periscope.nvim.json"
end

function load_workspace()
	local workspace_file_path = get_workspace_file_path()
	local file = io.open(workspace_file_path, "r")
	if file then
		local json_data = file:read("*a")
		file:close()
		local status, workspace_data = pcall(vim.fn.json_decode, json_data)
		if status then
			current_workspace = workspace_data
		else
		end
	else
		current_workspace = new_workspace()
	end
end

--Gets  or creates a new workspace
function get_current_workspace()
	if current_workspace == nil then
		load_workspace()
	end
	return current_workspace
end

-- Saves the current workspace
function save_workspace()
	local workspace = get_current_workspace()
	local workspace_file_path = get_workspace_file_path()
	local json_data = vim.fn.json_encode(workspace)
	local file = io.open(workspace_file_path, "w")
	if file then
		file:write(json_data)
		file:close()
		--print("Workspace saved to " .. workspace_file_path)
	else
		print("Error saving periscope workspace to " .. workspace_file_path)
	end
end

-- Sets the current task
function set_current_task(task_id)
	local workspace = get_current_workspace()
	workspace.current_task_id = task_id
	local task = get_current_task()
	downgrade_tasks()
	task.usage = START_TASK_USAGE
	remove_deleted_files_from_current_tasks() --just to clean up the list..there might be a better place to do this
end

function downgrade_tasks()
	local workspace = get_current_workspace()
	workspace.tasks = lume.map(workspace.tasks, function(task)
		if task.usage == nil then
			task.usage = 0
		end
		task.usage = task.usage - 1
		if task.usage < 0 then
			task.usage = 0
		end
		return task
	
	end)
	
end

-- Appends a task to the workspace
function append_task(task)
	local workspace = get_current_workspace()
	workspace.task = lume.push(workspace.tasks, task)
	save_workspace()
end

-- Creates a new task and adds it to the workspace
function create_task(name)
	local workspace = get_current_workspace()
	workspace.task_id = workspace.task_id + 1
	local task_id = workspace.task_id;
	local task = {
		usage=START_TASK_USAGE, 
		id = task_id,
		name = name,
		files = {}

	}
	append_task(task)
	set_current_task(task_id);
	--add current file to task
	--buffer_entered(vim.api.nvim_buf_get_name(0))
end

---- Creates a new task, promts user for a name
function copy_current_task()
	local current_task = get_current_task()
	if current_task then
		vim.ui.input({ prompt = 'New task name:', default = current_task.name }, function(input)
			if input then
				local workspace = get_current_workspace()
				workspace.task_id = workspace.task_id + 1
				local new_task = script.deepcopy(current_task)
				new_task.name = input
				new_task.id = workspace.task_id
				append_task(new_task)
				set_current_task(new_task.id);
				save_workspace()
				nvimtree().filter_tree()
			else
			end
		end)
	else
		print("No current task to rename")
	end
end

-- Creates a new task, promts user for a name
function rename_current_task()
	local current_task = get_current_task()
	if current_task then
		vim.ui.input({ prompt = 'Rename task:', default = current_task.name }, function(input)
			if input then
				current_task.name = input
				save_workspace()
			else
			end
		end)
	else
		print("No current task to rename")
	end
end

-- Creates a new task, promts user for a name
function new_task()
	vim.ui.input({ prompt = 'Enter task name: ' }, function(input)
		if input then
			create_task(input)
			nvim_tree.set_filter_enabled(true)
		else
		end
	end)
end

-- Gets the current task
function get_current_task()
	local workspace = get_current_workspace()
	return lume_e.find_f(workspace.tasks, function(task)
		return task.id == workspace.current_task_id
	end)
end

function get_current_task_name()
	local task = get_current_task()
	if task then
		return task.name
	else
		return nil
	end
end

-- Removes files that have been deleted from the current task
function remove_deleted_files_from_current_tasks()
	local current_task = get_current_task()
	-- print("Removing deleted files from current task")
	if current_task == nil then
		return
	end
	local filteres_files = lume.filter(current_task.files, function(file)
		--check if file contains /tmp/ (this is a temporary file)
                 if string.find(file.path,"/tmp/") then 
			 return false
		 end
		--check if file exists
		local exists = vim.fn.filereadable(file.path) == 1;
		--print("Checking if file exists 2: " .. file.path .. tostring(exists))
		--	if exists then
		--		print("File does exist: " .. file.path)
		--	end
		return exists
	end)
	current_task.files = filteres_files
	save_workspace()
end

-- Removes a file from the current task
function remove_file_from_current_task(path)
	local task = get_current_task()
	if task then
		for i, file in ipairs(task.files) do
			if file.path == path then
				table.remove(task.files, i)
				break
			end
		end
	end
end

-- Adds a file to the current task
function add_file_to_current_task(path)
	-- Check if the file is in the .git directory
	if string.match(path, "/%.git/") then
		return
	end
	local task = get_current_task()
	if task then
		remove_file_from_current_task(path)
		local file = new_file(path)
		table.insert(task.files, file)
	else
		print("Cannot add file to current task")
	end
end

-- Downgrades the usage of all files in a task
function downgrade_files(task)
	for i, file in ipairs(task.files) do
		file.usage = file.usage - 1
		if file.usage < 0 then
			table.remove(task.files, i)
		end
	end
end

function get_file_for_current_task(path)
	local task = get_current_task()
	if task then
		for i, file in ipairs(task.files) do
			if file.path == path then
				return file
			end
		end
	end
	return nil
end

-- Called when a buffer is entered
function buffer_entered(path)
	remove_deleted_files_from_current_tasks() --just to clean up the list..there might be a better place to do this
	if not vim.fn.filereadable(path) then
		return
	end
	local path = utils.to_relative_path(path)
	local current_task = get_current_task()
	--print("Buffer entered: " .. path)
	if current_task then
		downgrade_files(current_task)
		add_file_to_current_task(path)
		save_workspace()
		nvim_tree.filter_tree()
	end
end

-- Called when a buffer is left
function buffer_left(path)
	local path = utils.to_relative_path(path)
	local left_file = get_file_for_current_task(path)
	if left_file then
		--print("Buffer recently_left left: " .. path)
		get_current_workspace().last_file = path
		save_workspace()
	end
end

-- Gets all tasks
function get_all_tasks()
	local workspace = get_current_workspace()
	return workspace.tasks
end

-- Deletes the current taskæ
function delete_current_task()
	local current_task = get_current_task()
	if current_task then
		local confirm = vim.fn.confirm("Delete task :'" .. current_task.name .. "'", "&Yes\n&No", 2)
		if confirm == 1 then
			local workspace = get_current_workspace()
			workspace.tasks = lume.filter(workspace.tasks, function(task)
				return task.id ~= workspace.current_task_id
			end)
			workspace.current_task_id = nil
			save_workspace()
			nvim_tree.unfilter_tree()
			print("Task deleted")
		end
	else
		print("No current task to delete")
	end
end

-- Gets the current task id
function get_current_task_id()
	local workspace = get_current_workspace()
	return workspace.current_task_id
end

return {
	remove_deleted_files_from_current_tasks = remove_deleted_files_from_current_tasks,
	new_task = new_task,
	buffer_entered = buffer_entered,
	buffer_left = buffer_left,
	get_current_task = get_current_task,
	set_current_task = set_current_task,
	create_task = create_task,
	add_file_to_current_task = add_file_to_current_task,
	get_all_tasks = get_all_tasks,
	get_current_workspace = get_current_workspace,
	get_current_task_name = get_current_task_name,
	delete_current_task = delete_current_task,
	get_current_task_id = get_current_task_id,
	rename_current_task = rename_current_task,
	copy_current_task = copy_current_task




}
