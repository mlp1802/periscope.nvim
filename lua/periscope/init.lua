local enabled = true
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
--forward declarations
local setup_auto_commands, setup_user_commands, setup, run

local function run(f)
	if enabled then
		f()
	else
		print("Periscope is not enabled")
	end
end
local function setup_auto_commands()
	local augroup = vim.api.nvim_create_augroup("Periscope", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter",
		{ group = augroup, desc = "", once = true, callback = main })

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			if not enabled then
				return
			end
			model().buffer_entered(args.file)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave" }, {
		pattern = { "*.*" },
		group = augroup,
		callback = function(args)
			if not enabled then
				return
			end

			model().buffer_left(args.file)
		end,
	})
end
local function setup_user_commands()
	vim.api.nvim_create_user_command('PeriscopeCopyCurrentTask', function()
		run(function()
			model().copy_current_task()
		end)
	end, {})

	vim.api.nvim_create_user_command('PeriscopeNewTask', function()
		run(function()
			model().new_task()
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeEnable', function()
		enabled = true
		print("Periscope enabled")
		nvimtree().set_filter_enabled(true)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDisable', function()
		enabled = false
		print("Periscope disabled")
		nvimtree().unfilter_tree()
	end, {})


	vim.api.nvim_create_user_command('PeriscopeShowFiles', function()
		run(function()
			pickers().show_files_for_current_task()
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeShowTasks', function()
		run(function()
			pickers().show_all_tasks()
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDeleteCurrentTask', function()
		run(function()
			model().delete_current_task()
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeEnableFilter', function()
		run(function()
			nvimtree().set_filter_enabled(true)
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeDisableFilter', function()
		run(function()
			nvimtree().set_filter_enabled(false)
		end)
	end, {})
	vim.api.nvim_create_user_command('PeriscopeRenameCurrentTask', function()
		run(function()
			model().rename_current_task()
		end)
	end, {})
end
function setup(enabled)
	enabled = enabled
	nvimtree().set_filter_enabled(enabled)
	setup_auto_commands();
	setup_user_commands();
end

--setup(true)
return {
	setup = setup,
	model = model(),
	pickers = pickers(),


}
