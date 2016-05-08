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
		local pattern = strsub(tag, 2, -2)
		local matcher = self:fuzzy_matcher(strsub(tag, 2, -2))
		local best_match
		for item_id=1,20000 do
			local name, _, quality = GetItemInfo('item:'..item_id)
			if name then
				local rating = matcher(name)
				if rating and (not best_match or rating > best_match.rating or rating == best_match.rating and strlen(name) < strlen(best_match.name)) then
					best_match = { rating = rating, item_id = item_id, name = name, quality = quality }
				end
			end
		end
		if best_match then
			local color = strsub(({GetItemQualityColor(best_match.quality)})[4], 3)
			return format(LINK_TEMPLATE, color, best_match.item_id, 0, 0, 0, best_match.name)
		else
			return format('[%s]', pattern)
		end
	end)
end

function linkmend:fuzzy_matcher(input)
	local uppercase_input = strupper(input)
	local pattern = '(.*)'
	for i=1,strlen(uppercase_input) do
		if strfind(strsub(uppercase_input, i, i), '%w') or strfind(strsub(uppercase_input, i, i), '%s') then
			pattern = pattern .. strsub(uppercase_input, i, i) .. '(.-)'
 		end
	end
	return function(candidate)
		local match = { strfind(strupper(candidate), pattern) }
		if match[1] then
			local rating = 0
			for i=4,getn(match)-1 do
				if strlen(match[i]) == 0 then
					rating = rating + 1
				end
 			end
			return rating
 		end
	end
end

function linkmend:ADDON_LOADED()
	if arg1 ~= 'linkmend' then
		return
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