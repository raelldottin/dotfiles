--import mason plugin safely
local status, mason = pcall(require, "mason")
if not status then
	return
end

--configure treesitter
mason.setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})
