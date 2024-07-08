local current_workspace = nil
local script = require('periscope.scripts')
local START_USAGE = 10
local function new_file(path)
	return {
		path = path,
		usage = START_USAGE,
	}
end
-- creates a new workspace
local function new_workspace()
	local workspace = {
		task_id = 0,
		current_task_id = 0,
		tasks = {}
	}
	return workspace
end

--Gets  or creates a new workspace
local function get_current_workspace()
	if current_workspace == nil then
		current_workspace = new_workspace()
	end
	return current_workspace
end

-- Sets the current task
local function set_current_task(task_id)
	local workspace = get_current_workspace()
	workspace.current_task_id = task_id
end

-- Creates a new task and adds it to the workspace
local function create_task(name)
	local workspace = get_current_workspace()
	local task_id = workspace.task_id
	workspace.task_id = workspace.task_id + 1
	local task = {
		id = task_id,
		name = name,
		files = {}

	}
	table.insert(workspace.tasks, task);
	set_current_task(task_id);
	print("Task created: " .. name)
end

-- Creates a new task, promts user for a name
local function new_task()
	vim.ui.input({ prompt = 'Enter task name: ' }, function(input)
		if input then
			create_task(input)
		else
			print("Task creation canceled")
		end
	end)
end

-- Gets the current task
local function get_current_task()
	local workspace = get_current_workspace()
	local task_id = workspace.current_task_id
	return workspace.tasks[task_id]
end


-- Shows files for the current task

-- Removes a file from the current task
local function remove_file_from_current_task(path)
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
local function add_file_to_current_task(path)
	local task = get_current_task()
	if task then
		print("ADDING FILE TO CURRENT TASK")
		remove_file_from_current_task(path)
		local file = new_file(path)
		table.insert(task.files, file)
	else
		print("CANNOT ADD FILE TO CURRENT TASK")
	end
end

-- Downgrades the usage of all files in a task
local function downgrade_files(task)
	for i, file in ipairs(task.files) do
		file.usage = file.usage - 1
		if file.usage < 0 then
			table.remove(task.files, i)
		end
	end
end

-- Called when a buffer is entered
local function buffer_entered(path)
	local current_task = get_current_task()
	if current_task then
		add_file_to_current_task(path)
		downgrade_files(current_task)
	end
end

local function get_all_tasks()
	local workspace = get_current_workspace()
	return workspace.tasks
end


local function get_all_files_for_current_task()
	local task = get_current_task()
	return task.files
end
--Test

return {
	new_task = new_task,
	buffer_entered = buffer_entered,
	get_current_task = get_current_task,
	set_current_task = set_current_task,
	create_task = create_task,
	add_file_to_current_task = add_file_to_current_task,
	get_all_tasks = get_all_tasks,

}
