local linkmend = CreateFrame('Frame')
linkmend:SetScript('OnEvent', function()
	this[event](this)
end)
linkmend:RegisterEvent('ADDON_LOADED')

local CLINK_PATTERN = '%{CLINK:(%x%x%x%x%x%x%x%x):(%d*):(%d*):(%d*):(%d*):(.-)%}'

local LINK_PATTERN = '|c(%x%x%x%x%x%x%x%x)|Hitem:(%d*):(%d*):(%d*):(%d*)[:0-9]*|h%[(.-)%]|h|r'

local LINK_TEMPLATE = '|c%s|Hitem:%s:%s:%s:%s|h[%s]|h|r'

function linkmend:mend_clinks(text)
	return string.gsub(text, CLINK_PATTERN, function(color, item_id, enchant_id, suffix_id, unique_id, name)
		return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, name)
	end)
end

function linkmend:mend_links(text)
	return string.gsub(text, LINK_PATTERN, function(color, item_id, enchant_id, suffix_id, unique_id, name)
		local cached_name, _, quality = GetItemInfo(format('item:%s:0:%s', item_id, suffix_id))
		if cached_name then
			local color = strsub(({GetItemQualityColor(quality)})[4], 3)
			return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, cached_name)
		else
			return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, name)
		end
	end)
end

function linkmend:mend_tags(text)
	return string.gsub(text, '%b<>', function(tag)
		local name = strsub(tag, 2, -2)
		local item_info = self.item_cache[strupper(name)]
		if item_info then
			local color = strsub(({GetItemQualityColor(item_info.quality)})[4], 3)
			return format(LINK_TEMPLATE, color, item_info.item_id, 0, 0, 0, item_info.name)
		else
			return format('[%s]', pattern)
		end
	end)
end

function linkmend:ADDON_LOADED()
	if arg1 ~= 'linkmend' then
		return
	end

	self.item_cache = {}
	for item_id=1,20000 do
		local name, _, quality = GetItemInfo('item:'..item_id)
		if name then
			self.item_cache[strupper(name)] = { item_id = item_id, name = name, quality = quality }
		end
	end

	local orig_ChatFrame_OnEvent = ChatFrame_OnEvent
	ChatFrame_OnEvent = function(event)
		if event == 'CHAT_MSG_CHANNEL'
			or event == 'CHAT_MSG_GUILD'
			or event == 'CHAT_MSG_PARTY'
			or event == 'CHAT_MSG_RAID'
			or event == 'CHAT_MSG_RAID_LEADER'
			or event == 'CHAT_MSG_RAID_WARNING'
			or event == 'CHAT_MSG_WHISPER'
			or event == 'CHAT_MSG_SAY'
			or event == 'CHAT_MSG_YELL'
			or event == 'CHAT_MSG_BATTLEGROUND'
			or event == 'CHAT_MSG_BATTLEGROUND_LEADER'
			or event == 'CHAT_MSG_OFFICER'
			or event == 'CHAT_MSG_AFK'
			or event == 'CHAT_MSG_DND'
			or event == 'CHAT_MSG_EMOTE'
		then
			arg1 = self:mend_clinks(arg1)
			arg1 = self:mend_links(arg1)
		end
		return orig_ChatFrame_OnEvent(event)
	end

	local orig_SendChatMessage = SendChatMessage
	SendChatMessage = function(...)
		arg[1] = self:mend_tags(arg[1])
		return orig_SendChatMessage(unpack(arg))
	end
end