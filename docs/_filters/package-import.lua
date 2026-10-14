--- Shows the visual tests with the import line that a reader writes.
---
--- The visual tests import the working tree with `#import "/lib.typ"`, so no
--- test holds the version. This filter runs after typst-render and changes that
--- string to `@preview/keisen:<version>` in each Typst listing. The version
--- comes from typst.toml, which the release bump writes.

local MANIFEST = pandoc.path.join({
  pandoc.path.directory(PANDOC_SCRIPT_FILE), '..', '..', 'typst.toml',
})

local function manifest_version()
  local file = io.open(MANIFEST, 'r')
  if file == nil then
    error('package-import: cannot read the manifest; got ' .. MANIFEST .. '. Run the render from the docs project of a full clone.')
  end
  local text = file:read('a')
  file:close()
  local version = ('\n' .. text):match('\nversion%s*=%s*"([^"]+)"')
  if version == nil then
    error('package-import: typst.toml names no version; got none. Set version = "x.y.z" in typst.toml.')
  end
  return version
end

local IMPORT = '#import "@preview/keisen:' .. manifest_version() .. '"'

return {
  {
    CodeBlock = function(block)
      if not block.classes:includes('typst') then
        return nil
      end
      local text, count = block.text:gsub('#import "/lib%.typ"', IMPORT)
      if count == 0 then
        return nil
      end
      block.text = text
      return block
    end,
  },
}
