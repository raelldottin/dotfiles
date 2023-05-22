local status, autopairs, autopairs_rules, autopairs_ts_conds

status, autopairs = pcall(require, "nvim-autopairs")
if not status then
	return
end

status, autopairs_rules = pcall(require, "nvim-autopairs.rule")
if not status then
	return
end

status, autopairs_ts_conds = pcall(require, "nvim-autopairs.ts-conds")
if not status then
	return
end

-- configure autopairs
autopairs.setup({
	check_ts = true, -- enable treesitter
	ts_config = {
		lua = { "string" }, -- don't add pairs in lua string treesitter nodes
		javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
		java = false, -- don't check treesitter on java
	},
})

-- import nvim-autopairs completion functionality safely
local cmp_autopairs_setup, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
if not cmp_autopairs_setup then
	return
end

-- import nvim-cmp plugin safely (completions plugin)
local cmp_setup, cmp = pcall(require, "cmp")
if not cmp_setup then
	return
end

autopairs_rules.add_rules({
	autopairs_rules(require("nvim-autopairs.rules.endwise-lua")),
	autopairs_rules("%", "%", "lua"):with_pair(autopairs_ts_conds.is_ts_node({ "string", "comment" })),
	autopairs_rules("$", "$", "lua"):with_pair(autopairs_ts_conds.is_not_ts_node({ "function" })),
})

-- make autopairs and completion work together
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())