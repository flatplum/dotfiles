vim.filetype.add({
  pattern = {
    [".*%.ya?ml"] = function(_, buf)
      if vim.fs.root(buf, { "ansible.cfg", ".ansible-lint" }) then
        return "yaml.ansible"
      end

      return "yaml"
    end,
  },
})
