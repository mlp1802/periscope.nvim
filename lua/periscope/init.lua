function pickers()
	return require('periscope.pickers')
end

function model()
	return require('periscope.model')
end

function nvimtree()
	return require('periscope.nvim-tree')
end

local function main()
	print("Hello from our plugin")
end

local function setup_auto_commands()
	local augroup = vim.api.nvim_create_augroup("MyPluginGroup", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter",
		{ group = augroup, desc = "Set a fennel scratch buffer on load", once = true, callback = main })
	--	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	--		pattern = { "*.*" },
	--		group = augroup,
	--		callback = file_entered
	--	});
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			model().buffer_entered(args.file)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			model().buffer_left(args.file)
		end,
	})
end
local function setup_user_commands()
	vim.api.nvim_create_user_command('PeriscopeNewTask', function()
		model().new_task()
	end, {})
	vim.api.nvim_create_user_command('PeriscopeShowFiles', function()
		pickers().show_files_for_current_task()
	end, {})
	vim.api.nvim_create_user_command('PeriscopeShowTasks', function()
		pickers().show_all_tasks()
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDeleteCurrentTask', function()
		model().delete_current_task()
	end, {})
	vim.api.nvim_create_user_command('TaskTree', function()
		require('nvim-tree.api').tree.open()
		nvimtree().filter_nvim_tree_nodes() --vim.cmd('let g:NERDTreeNodeFilterFunction = function("v:lua.custom_filter")')
	end, {})
end

function setup(f)
	setup_auto_commands();
	setup_user_commands();
end

setup()
return {
	setup = setup,
	model = model(),
	pickers = pickers(),


}
