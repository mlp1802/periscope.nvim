local lume = require('periscope.lume')
local nvim_tree = require('periscope.nvim-tree')
local current_workspace = nil
local START_USAGE = 20
local lume_e = require('periscope.lume_extra')
local nvim_tree = require('periscope.nvim-tree')

--Forward declarations
local get_current_workspace, save_workspace, get_current_task, get_current_task_name, remove_files_from_current_tasks, new_task, buffer_entered, buffer_left, create_task, add_file_to_current_task, get_all_tasks, delete_current_task, get_current_task_id, rename_current_task
local function new_file(path)
	return {
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
			--print("Workspace loaded from " .. workspace_file_path)
		else
			--print("Error parsing workspace file: " .. workspace_file_path)
			-- Optionally, you can also delete the corrupted file or take some other action
		end
	else
		--print("No workspace file found at " .. workspace_file_path)
		current_workspace = new_workspace()
	end
end

--Gets  or creates a new workspace
function get_current_workspace()
	if current_workspace == nil then
		--print("Creating new workspace")
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
	save_workspace()
end

-- Creates a new task and adds it to the workspace
function create_task(name)
	local workspace = get_current_workspace()
	workspace.task_id = workspace.task_id + 1
	local task_id = workspace.task_id;
	local task = {
		id = task_id,
		name = name,
		files = {}

	}
	workspace.task = lume.push(workspace.tasks, task)
	set_current_task(task_id);
	--add current file to task
	buffer_entered(vim.api.nvim_buf_get_name(0))
	nvim_tree.filter_tree()
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

function remove_files_from_current_tasks()
	local current_task = get_current_task()
	if current_task == nil then
		return
	end
	local filteres_files = lume.filter(current_task.files, function(file)
		return vim.fn.filereadable(file.path)
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

-- Called when a buffer is entered
function buffer_entered(path)
	local current_task = get_current_task()
	--print("Buffer entered: " .. path)
	if current_task then
		downgrade_files(current_task)
		add_file_to_current_task(path)
		save_workspace()
		nvim_tree.filter_tree()
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

-- Called when a buffer is left
function buffer_left(path)
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
	local confirm = vim.fn.confirm("Delete task?", "&Yes\n&No", 2)
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
end

-- Gets the current task id
function get_current_task_id()
	local workspace = get_current_workspace()
	return workspace.current_task_id
end

return {
	remove_deleted_files_from_current_tasks = remove_files_from_current_tasks,
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
	rename_current_task = rename_current_task


}
