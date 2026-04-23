-- 1. Remove the first H1 from the body so it does not duplicate the
--    <h1> the template renders from --metadata=title.
-- 2. Rewrite local README.md links to directory-index URLs so that
--    cross-page links work after pandoc renders each file separately.
--    e.g.  utils/README.md#config-editor  →  utils/#config-editor

local found_title = false

function Header(el)
    if not found_title and el.level == 1 then
        found_title = true
        return {}
    end
end

function Link(el)
    el.target = el.target:gsub("README%.md", "")
    return el
end
