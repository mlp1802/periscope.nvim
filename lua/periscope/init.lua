local scripts = require('periscope.scripts');

function pickers()
	return require('periscope.pickers')
end

function model()
	return require('periscope.model')
end

local function main()
	print("Hello from our plugin")
end

local function setup_auto_commands()
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
			require('periscope.model').buffer_entered(args.file)
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
end
local function setup_shortcuts()
	vim.api.nvim_set_keymap('n', '<leader>tn', '<cmd>PeriscopeNewTask<cr>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<leader>tr', '<cmd>PeriscopeShowFiles<cr>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<leader>tt', '<cmd>PeriscopeShowTasks<cr>', { noremap = true, silent = true })
end
local function setup()
	setup_auto_commands();
	setup_user_commands();
	setup_shortcuts();
end
setup();
return {
	setup = setup,
	model = model(),
	pickers = pickers(),


}
