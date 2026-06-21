-- Configuración de Tabulación
vim.opt.tabstop = 4      -- El ancho visual de un tab
vim.opt.softtabstop = 4  -- Espacios que se insertan al presionar Tab
vim.opt.shiftwidth = 4   -- Espacios al usar comandos de indentación (>> o <<)
vim.opt.expandtab = true -- Convierte los tabs en espacios reales
vim.opt.smartindent = true -- Indentación inteligente automática

-- Opcional: Mostrar una línea vertical en el límite de 80 caracteres
-- vim.opt.colorcolumn = "80"

-- Opcional: Mostrar números de línea
vim.opt.number = true
-- opcional: Usar clipboard global
vim.opt.clipboard = "unnamedplus"
