local enabled = false
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

		end,
	})
	vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			model().buffer_left(args.file)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			print("Buffer deleted")
			--model().buffer_left(args.file)
		end,
	})
end
local function setup_user_commands()
	vim.api.nvim_create_user_command('PeriscopeNewTask', function()
		if enabled then
			model().new_task()
		else
			print("Periscope is not enabled")
		end
	end, {})
	vim.api.nvim_create_user_command('PeriscopeEnable', function()
		enabled = true
		print("Periscope enabled")
		nvimtree().filter_tree()
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDisable', function()
		enabled = false
		print("Periscope disabled")
		nvimtree().unfilter_tree()
	end, {})


	vim.api.nvim_create_user_command('PeriscopeShowFiles', function()
		if enabled then
			pickers().show_files_for_current_task()
		else
			print("Periscope is not enabled")
		end
	end, {})
	vim.api.nvim_create_user_command('PeriscopeShowTasks', function()
		if enabled then
			pickers().show_all_tasks()
		else
			print("Periscope is not enabled")
		end
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDeleteCurrentTask', function()
		if enabled then
			model().delete_current_task()
		else
			print("Periscope is not enabled")
		end
	end, {})
	vim.api.nvim_create_user_command('PeriscopeFilterTree', function()
		if enabled then
			nvimtree().filter_tree()
		else
			print("Periscope is not enabled")
		end
	end, {})
	vim.api.nvim_create_user_command('PeriscopeUnfilterTree', function()
		if enabled then
			nvimtree().unfilter_tree()
		else
			print("Periscope is not enabled")
		end
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
