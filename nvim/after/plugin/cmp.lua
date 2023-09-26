-- -- -- nvim-cmp setup
-- local cmp = require("cmp.")
-- local luasnip = require("luasnip")
--
-- cmp.setup({
-- 	pum = {
-- 		kind = "",
-- 		title = "",
-- 		border = "double",
-- 	},
-- 	window = {
-- 		completion = cmp.config.window.bordered(),
-- 		documentation = cmp.config.window.bordered(),
-- 	},
-- 	completion = {
-- 		completeopt = "menu,menuone,preview,noselect",
-- 	},
-- 	snippet = {
-- 		expand = function(args)
-- 			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
-- 		end,
-- 	},
-- 	mapping = cmp.mapping.preset.insert({
-- 		["<C-d>"] = cmp.mapping.scroll_docs(-4),
-- 		["<C-f>"] = cmp.mapping.scroll_docs(4),
-- 		["<C-Space>"] = cmp.mapping.complete(),
-- 		["<C-y>"] = cmp.mapping.confirm({
-- 			behavior = cmp.ConfirmBehavior.Replace,
-- 			select = true,
-- 		}),
-- 		["<Enter>"] = cmp.mapping(function(fallback)
-- 			if cmp.visible() then
-- 				cmp.select_next_item()
-- 			elseif luasnip.expand_or_jumpable() then
-- 				luasnip.expand_or_jump()
-- 			else
-- 				fallback()
-- 			end
-- 		end, { "i", "s" }),
-- 		["<S-Tab>"] = cmp.mapping(function(fallback)
-- 			if cmp.visible() then
-- 				cmp.select_prev_item()
-- 			elseif luasnip.jumpable(-1) then
-- 				luasnip.jump(-1)
-- 			else
-- 				fallback()
-- 			end
-- 		end, { "i", "s" }),
-- 	}),
-- 	sources = {
-- 		-- { name = "nvim_lsp" },
-- 		{ name = "luasnip" },
-- 	},
-- })
vim.opt.completeopt = { "menu", "menuone", "noselect" }

require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("cmp")
local luasnip = require("luasnip")

local select_opts = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	sources = {
		{ name = "luasnip",  keyword_length = 2 },
		{ name = "buffer",   keyword_length = 3 },
		{ name = "nvim_lsp", keyword_length = 1 },
		{ name = "path" },
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	formatting = {
		fields = { "menu", "abbr", "kind" },
		format = function(entry, item)
			local menu_icon = {
				nvim_lsp = "λ",
				luasnip = "⋗",
				buffer = "Ω",
				path = "🖫",
			}

			item.menu = menu_icon[entry.source.name]
			return item
		end,
	},
	mapping = {
		["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
		["<C-n>"] = cmp.mapping.select_next_item(select_opts),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-y>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Enter>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
		-- 	["<Up>"] = cmp.mapping.select_prev_item(select_opts),
		-- 	["<Down>"] = cmp.mapping.select_next_item(select_opts),
		--
		-- 	["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
		-- 	["<C-n>"] = cmp.mapping.select_next_item(select_opts),
		--
		-- 	["<C-u>"] = cmp.mapping.scroll_docs(-4),
		-- 	["<C-d>"] = cmp.mapping.scroll_docs(4),
		--
		-- 	["<C-e>"] = cmp.mapping.abort(),
		-- 	["<C-y>"] = cmp.mapping.confirm({ select = true }),
		-- 	["<CR>"] = cmp.mapping.confirm({ select = false }),
		--
		-- 	["<C-f>"] = cmp.mapping(function(fallback)
		-- 		if luasnip.jumpable(1) then
		-- 			luasnip.jump(1)
		-- 		else
		-- 			fallback()
		-- 		end
		-- 	end, { "i", "s" }),
		--
		-- 	["<C-b>"] = cmp.mapping(function(fallback)
		-- 		if luasnip.jumpable(-1) then
		-- 			luasnip.jump(-1)
		-- 		else
		-- 			fallback()
		-- 		end
		-- 	end, { "i", "s" }),
		--
		-- 	["<Tab>"] = cmp.mapping(function(fallback)
		-- 		local col = vim.fn.col(".") - 1
		--
		-- 		if cmp.visible() then
		-- 			cmp.select_next_item(select_opts)
		-- 		elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
		-- 			fallback()
		-- 		else
		-- 			cmp.complete()
		-- 		end
		-- 	end, { "i", "s" }),
		--
		-- 	["<S-Tab>"] = cmp.mapping(function(fallback)
		-- 		if cmp.visible() then
		-- 			cmp.select_prev_item(select_opts)
		-- 		else
		-- 			fallback()
		-- 		end
		-- 	end, { "i", "s" }),
	},
})
