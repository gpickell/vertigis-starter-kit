-- Remove the first H1 from the document body.
-- The title is injected by the pandoc template from --metadata=title,
-- so leaving the H1 in the body would duplicate it.
local found = false

function Header(el)
    if not found and el.level == 1 then
        found = true
        return {}
    end
end
