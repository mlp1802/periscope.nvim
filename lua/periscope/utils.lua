-- Convert an absolute path to a relative path
local function to_relative_path(absolute_path)
	return vim.fn.fnamemodify(absolute_path, ":~:.")
end

-- Convert a relative path to an absolute path
local function to_absolute_path(relative_path)
	return vim.fn.fnamemodify(relative_path, ":p")
end
return {
	to_relative_path = to_relative_path,
	to_absolute_path = to_absolute_path,
}
