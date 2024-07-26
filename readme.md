## Periscope.nvim

Periscope is a plugin that provides a task focused interface for Neovim. It is inspired by Mylyn for Eclipse.

It intergrates with nvim-tree, and uses Telescope for task and file searching. It allows you to create tasks, add files to tasks, and view tasks. It also provides a way to view the files that are associated with a task.

So what does it do, excatly? Well have you ever wondered why a file tree shows you close to a billion files when you are only working on a few? Periscope allows you to focus on the files that are important to you, and allows you to quickly find the files you need.
In fact, all the files you need for a particuluar task will probably all be visible to you simultaneously.

When working on a task, it will show you the files that are associated with that task. When opening files that are not associated with the task, they will be added to task and become visible in the file tree.

Periscope will keep track of how much you are using each files, once you stop using a file for a longer period of time, it will be removed from the task.
You select the files through either the file tree (when filtering is disabled) or through telescope, standard file manager or similar. 
Point is, as soon as you have selected a file, it will be added to the task and be part of your task focused interface.

## Installation
### lazy.nvim package manager

```lua
return {
	"mlp1802/periscope.nvim",
	name = "periscope",
	dependencies = {
		{ "nvim-tree/nvim-tree.lua" }, { "nvim-telescope/telescope.nvim" },
	},
	config = function()
		require('periscope').setup(true) --set to false if you don't want Periscope to start on startup
	end
}
```

## Commands
- `:PeriscopeEnable` - Enable Periscope
- `:PeriscopeDisable` - Disable Periscope
- `:PeriscopeFilterTree` - Filters the tree (default behavior)
- `:PeriscopeUnfilterTree` - Unfilter tree 
- `:PeriscopeNewTask` - Creates a new task
- `:PeriscopeDeleteCurrentTask` - Deletes the current task
- `:PeriscopeRenameCurrentTask` - Renames the current task
- `:PeriscopeCopyCurrentTask` - Makes a copy of the current task
- `:PeriscopeShowFiles` - Opens a file selector for files associated with the current task. Only shows file names, not entire path
- `:PeriscopeShowFilesFullPath` - Opens a file selector for files associated with the current task. Shows entire path relative to projection directory
- `:PeriscopeShowTasks` - Opens a task selector

Note, this is my first plugin, so there might be some bugs. Please report them if you find any.

Tasks are saved in ${pwd}/.periscope.nvim.json


