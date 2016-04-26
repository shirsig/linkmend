local linkmend = CreateFrame('Frame', nil, UIParent)
linkmend:SetScript('OnEvent', function()
	this[event](this)
end)
linkmend:RegisterEvent('ADDON_LOADED')

local CLINK_PATTERN = '%{CLINK:(%x%x%x%x%x%x%x%x):(%d*):(%d*):(%d*):(%d*):([^}]*)%}'

local LINK_PATTERN = '|c%x%x%x%x%x%x%x%x|Hitem:(%d*):(%d*):(%d*):(%d*)[:0-9]*|h%[[^]]*%]|h|r'

local LINK_TEMPLATE = '|c%s|Hitem:%s:%s:%s:%s|h[%s]|h|r'

function linkmend.mend_clinks(text)
	return string.gsub(text, CLINK_PATTERN, function(color, item_id, enchant_id, suffix_id, unique_id, name)
		return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, name)
	end)
end

function linkmend.mend_links(text)
	return string.gsub(text, LINK_PATTERN, function(item_id, enchant_id, suffix_id, unique_id)
		local name, _, quality = GetItemInfo(format('item:%s:0:%s', item_id, suffix_id))
		if name then
			local color = strsub(({GetItemQualityColor(quality)})[4], 3)
			return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, name)
		end
	end)
end

function linkmend:ADDON_LOADED()
	if arg1 ~= 'linkmend' then
		return
	end

	local orig_ChatFrame_OnEvent = ChatFrame_OnEvent
	ChatFrame_OnEvent = function(event)
		if event == 'CHAT_MSG_CHANNEL' then
			arg1 = linkmend.mend_clinks(arg1)
			arg1 = linkmend.mend_links(arg1)
		end
		return orig_ChatFrame_OnEvent(event)
	end
end