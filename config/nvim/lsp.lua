-- Serveurs de langage de nvim (0.11 et plus), chargé par le vimrc commun. Chaque serveur n'est activé que s'il est
-- installé (modules rustup, ruff, ty, tinymist). Raccourcis d'origine de nvim : K, grn, gra, grr, gri, [d, ]d, gO.
if vim.fn.has('nvim-0.11') == 0 then return end

vim.lsp.config('rust_analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = { ['rust-analyzer'] = { check = { command = 'clippy' } } },
})
vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
})
-- Python : ruff pour les erreurs et le formatage, ty pour la complétion, la doc et les types.
vim.lsp.config('ty', {
  cmd = { 'ty', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ty.toml', '.git' },
})
vim.lsp.config('tinymist', {
  cmd = { 'tinymist' },
  filetypes = { 'typst' },
  root_markers = { '.git' },
  settings = { formatterMode = 'typstyle' },
})

-- rustup crée la commande rust-analyzer même sans le composant : on cherche le composant lui-même.
local installed = {
  rust_analyzer = vim.fn.glob('~/.rustup/toolchains/*/bin/rust-analyzer') ~= '',
  ruff = vim.fn.executable('ruff') == 1,
  ty = vim.fn.executable('ty') == 1,
  tinymist = vim.fn.executable('tinymist') == 1,
}
for name, ok in pairs(installed) do
  if ok then vim.lsp.enable(name) end
end

-- Complétion pendant la frappe, et formatage à l'enregistrement.
vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    -- Vérifié à l'enregistrement : certains serveurs (ruff, tinymist) annoncent le formatage après leur démarrage.
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = args.buf,
      callback = function()
        if client:supports_method('textDocument/formatting', args.buf) then
          vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
        end
      end,
    })
  end,
})

-- Erreurs en fin de ligne, icônes Nerd Font dans la marge.
vim.diagnostic.config({
  virtual_text = true,
  signs = { text = {
    [vim.diagnostic.severity.ERROR] = '\u{f057}',
    [vim.diagnostic.severity.WARN] = '\u{f071}',
    [vim.diagnostic.severity.INFO] = '\u{f05a}',
    [vim.diagnostic.severity.HINT] = '\u{f0eb}',
  } },
})
