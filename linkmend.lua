local linkmend = CreateFrame('Frame')
linkmend:SetScript('OnEvent', function()
	this[event](this)
end)
linkmend:RegisterEvent('ADDON_LOADED')

local CITEMLINK_PATTERN = '%{CLINK:(%x%x%x%x%x%x%x%x):(%d*):(%d*):(%d*):(%d*):(.-)%}'

local ITEMLINK_PATTERN = '|c(%x%x%x%x%x%x%x%x)|Hitem:(%d*):(%d*):(%d*):(%d*)[:0-9]*|h%[(.-)%]|h|r'
local ENCHANTLINK_PATTERN = '|c(%x%x%x%x%x%x%x%x)|Henchant:(%d*)|h%[(.-)%]|h|r'


local LINK_TEMPLATE = '|c%s|Hitem:%s:%s:%s:%s|h[%s]|h|r'

function linkmend:mend_clinks(text)
	return gsub(text, CITEMLINK_PATTERN, function(color, item_id, enchant_id, suffix_id, unique_id, name)
		return format(LINK_TEMPLATE, color, item_id, enchant_id, suffix_id, unique_id, name)
	end)
end

function linkmend:mend_links(text)
	return gsub(text, ITEMLINK_PATTERN, function(color, item_id, enchant_id, suffix_id, unique_id, name)
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
	local position = 1
	while true do
		tag_start, tag_end, tag = strfind(text, '(%b[])', position)
		if not tag_start then
			break
		end

		local itemlink_start, itemlink_end = strfind(text, ITEMLINK_PATTERN, position)
		local enchantlink_start, enchantlink_end = strfind(text, ENCHANTLINK_PATTERN, position)
		if itemlink_start and itemlink_start < tag_start then
			position = itemlink_end + 1
		elseif enchantlink_start and enchantlink_start < tag_start then
			position = enchantlink_end + 1
		else
			local link
			local name = strsub(tag, 2, -2)
			local item_info = self.item_cache[strupper(name)]
			if item_info then
				local color = strsub(({GetItemQualityColor(item_info.quality)})[4], 3)
				link = format(LINK_TEMPLATE, color, item_info.item_id, 0, 0, 0, item_info.name)
			else
				link = format('[%s]', name)
			end

			text = strsub(text, 1, tag_start - 1)..link..strsub(text, tag_end + 1)
			position = tag_start + strlen(link)
		end
	end
	return text
end

function linkmend:ADDON_LOADED()
	if arg1 ~= 'linkmend' then
		return
	end

	self.item_cache = {}
	for item_id=1,20000 do
		local name, _, quality = GetItemInfo('item:'..item_id)
		if name then
			self.item_cache[strupper(name)] = {item_id=item_id, name=name, quality=quality}
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