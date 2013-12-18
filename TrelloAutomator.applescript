on run {input, parameters}
	
	set theAppKey to "XXX-your-app-key-XXX"
	set theUserToken to "XXX-your-user-token-XXX"
	
	set theBoardTitle to "Inbox Board" -- whatever appropriate name is
	set theListTitle to "To Do"
	set success to true
	
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789 " -- shortcut to filter out characters that wont survive
	
	tell application "Mail"
		set selectedMessages to selection
		
		if (count of selectedMessages) is equal to 0 then
		else
			set theMessage to item 1 of selectedMessages
			
			set theSubject to subject of theMessage
			set theSender to sender of theMessage
			set theMessageId to message id of theMessage
			set theDateReceived to date received of theMessage
			set theMessageBody to content of theMessage
			tell (sender of theMessage)
				set theSenderName to (extract name from it)
			end tell
			
			if length of theMessageBody < 80 then
				set bodyBrief to theMessageBody
			else
				set bodyBrief to ((characters 1 thru 80 of theMessageBody) as string)
			end if
			set the_encoded_text to ""
			repeat with this_char in bodyBrief
				if this_char is in the standard_characters then
					set the_encoded_text to (the_encoded_text & this_char)
				else
					-- can't figure out real encoding so just replace characters that we can't deal with using underscores
					set the_encoded_text to (the_encoded_text & "_")
				end if
			end repeat
			set bodyBrief to the_encoded_text
			
			repeat with this_char in theSubject
				if this_char is in the standard_characters then
					set the_encoded_text to (the_encoded_text & this_char)
				else
					set the_encoded_text to (the_encoded_text & "_")
				end if
			end repeat
			set theSubject to the_encoded_text
			
			if theMessageId is "" then
				tell application "Finder" to display dialog "Could not find the message id for the selected message."
				error 1
			end if
			
			-- creates a URL to the message, sadly it's not working from Chrome.			
			set message_url to "[" & theSubject & "](message://%3C" & Â
				theMessageId & Â
				"%3E" & ")"
			
			tell application "JSON Helper"
				set jsonString to fetch JSON from "https://trello.com/1/members/my/boards?key=" & theAppKey & "&token=" & theUserToken
				set numBoards to count of jsonString
				
				if numBoards is 0 then
					tell application "Finder" to display dialog "error receiving list of boards"
					error 2
				end if
				
				set success to false
				repeat with ii from 1 to numBoards
					
					-- get the title
					set boardTitle to |name| of item ii of jsonString as string
					-- see if it's our board, if so we're done.
					if theBoardTitle = boardTitle then
						set boardId to |id| of item ii of jsonString
						log boardId
						set success to true
						exit repeat
					end if
					
				end repeat
				
				if success is false then
					tell application "Finder" to display dialog "Could not find the board with the title " & theBoardTitle
					error 3
				end if
				
				-- get the list of my boards
				set jsonString to fetch JSON from "https://trello.com/1/boards/" & boardId & "/lists?key=" & theAppKey & "&token=" & theUserToken
				set numLists to count of jsonString
				
				if numLists is 0 then
					tell application "Finder" to display dialog "error receiving list of lists in the board"
					error 4
				end if
				
				-- for each list
				set success to false
				repeat with ii from 1 to numLists
					
					-- get the title
					set listTitle to |name| of item ii of jsonString as string
					log listTitle
					
					-- see if it's "To Do", if so we're done.
					if theListTitle = listTitle then
						set listId to |id| of item ii of jsonString
						log listId
						set success to true
						exit repeat
					end if
					
				end repeat
				
				if success is false then
					tell application "Finder" to display dialog "Could not find the list with the title " & theListTitle
					error 5
				end if
				
				set itemName to theSenderName & ":" & theSubject
				set itemDesc to message_url & return & theDateReceived & return & bodyBrief & "..."
				
				set curlPostCmd to "curl -s -X POST"
				set curlURL to "https://api.trello.com/1/lists/" & listId & "/cards"
				set curlOpts to "-d name='" & itemName & "' -d desc='" & itemDesc & "' -d key=" & theAppKey & " -d token=" & theUserToken
				set curlOutput to do shell script curlPostCmd & " " & curlURL & " " & curlOpts
				set jsonString to read JSON from curlOutput
				set outputURL to shortUrl of jsonString
				
				tell application "Google Chrome"
					activate
					if (count every window) = 0 then
						make new window
					end if
					tell window 1 to make new tab with properties {URL:outputURL}
				end tell
				
				--tell application "Finder" to display dialog outputURL
				
			end tell
			
		end if
	end tell
	
	return input
end run