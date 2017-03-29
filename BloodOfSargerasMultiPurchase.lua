
BloodOfSargerasMultiPurchase = LibStub("AceAddon-3.0"):NewAddon("BloodOfSargerasMultiPurchase", "AceHook-3.0")

function BloodOfSargerasMultiPurchase:OnEnable()
	
	-- Hook all of the required functions involved to override WoW's default
	-- behavior, which doesn't allow multi-purchase at Blood of Sargeras Vendor.
	BloodOfSargerasMultiPurchase:RawHook("OpenStackSplitFrame", true);
	BloodOfSargerasMultiPurchase:RawHook("MerchantItemButton_OnClick", true);
	BloodOfSargerasMultiPurchase:RawHook("StackSplitFrameRight_Click", true);
	BloodOfSargerasMultiPurchase:RawHook("StackSplitFrameLeft_Click", true);
	BloodOfSargerasMultiPurchase:RawHook("StackSplitFrame_OnKeyDown", true);
	BloodOfSargerasMultiPurchase:RawHook("StackSplitFrame_OnChar", true);
	BloodOfSargerasMultiPurchase:RawHookScript(StackSplitOkayButton, "OnClick", "StackSplitFrameOkay_Click");
	BloodOfSargerasMultiPurchase:RawHookScript(StackSplitRightButton, "OnClick", "StackSplitFrameRight_Click");
	BloodOfSargerasMultiPurchase:RawHookScript(StackSplitLeftButton, "OnClick", "StackSplitFrameLeft_Click");
	
end

function BloodOfSargerasMultiPurchase:OnDisable()

	-- TODO: Does Ace handle this for us already?
	BloodOfSargerasMultiPurchase:UnhookAll();

end

-- This is the main entry point to take things over. Tried starting
-- with "MerchantItemButton_OnModifiedClick", but felt it ended up being
-- more invasive and prone to breaking on future updates. May have to
-- switch back eventually depending on what gets introduced later on.
function BloodOfSargerasMultiPurchase:MerchantItemButton_OnClick(caller, button)
	
	-- Handle Blood of Sargeras vendor multi-purchase logic hook here
	if (IsModifiedClick("SPLITSTACK")) then
		local merchantItemIndex = caller:GetID();
		local availableBloodOfSargeras = GetItemCount("Blood of Sargeras", true);
		local _, _, _, quantity, _, _, _ = GetMerchantItemInfo(merchantItemIndex);
		OpenStackSplitFrame((availableBloodOfSargeras * quantity), caller, "BOTTOMLEFT", "TOPLEFT", quantity);
		
	-- Call original logic for all other use-cases
	else
		self.hooks["MerchantItemButton_OnClick"](caller, button);
		
	end

end

-- Override for StackSplitFrame.lua:OpenStackSplitFrame(maxStack, parent, anchor, anchorTo)
function BloodOfSargerasMultiPurchase:OpenStackSplitFrame(maxStack, parent, anchor, anchorTo, itemIncrement)
	
	if ( StackSplitFrame.owner ) then
		StackSplitFrame.owner.hasStackSplit = 0;
	end
	
	if ( not maxStack or maxStack < 1 ) then
		StackSplitFrame:Hide();
		return;
	end

	StackSplitFrame.maxStack = maxStack;
	StackSplitFrame.owner = parent;
	StackSplitFrame.itemIncrement = itemIncrement;
	parent.hasStackSplit = 1;
	StackSplitFrame.split = (itemIncrement or 1);
	StackSplitFrame.typing = 0;
	StackSplitText:SetText(StackSplitFrame.split);
	StackSplitLeftButton:Disable();
	StackSplitRightButton:Enable();

	StackSplitFrame:ClearAllPoints();
	StackSplitFrame:SetPoint(anchor, parent, anchorTo, 0, 0);
	StackSplitFrame:Show();
	
end

-- Override for StackSplitFrame.lua:StackSplitFrameLeft_Click()
function BloodOfSargerasMultiPurchase:StackSplitFrameLeft_Click()

	if ( StackSplitFrame.split == (StackSplitFrame.itemIncrement or 1) ) then
		return;
	end
	
	local mod = StackSplitFrame.split % (StackSplitFrame.itemIncrement or 1);
	if (mod ~= 0) then
		StackSplitFrame.split = StackSplitFrame.split - mod;
	else
		StackSplitFrame.split = StackSplitFrame.split - (StackSplitFrame.itemIncrement or 1);
	end
	
	StackSplitText:SetText(StackSplitFrame.split);
	
	if ( StackSplitFrame.split == (StackSplitFrame.itemIncrement or 1) ) then
		StackSplitLeftButton:Disable();
	end
	
	StackSplitRightButton:Enable();
	
end

-- Override for StackSplitFrame.lua:StackSplitFrameRight_Click()
function BloodOfSargerasMultiPurchase:StackSplitFrameRight_Click()
	
	if ( StackSplitFrame.split == StackSplitFrame.maxStack ) then
		return;
	end

	local mod = StackSplitFrame.split % (StackSplitFrame.itemIncrement or 1);
	if (mod > 0) then
		StackSplitFrame.split = StackSplitFrame.split + (StackSplitFrame.itemIncrement - mod);
	else
		StackSplitFrame.split = StackSplitFrame.split + (StackSplitFrame.itemIncrement or 1);
	end
	
	StackSplitText:SetText(StackSplitFrame.split);
	if ( StackSplitFrame.split == StackSplitFrame.maxStack ) then
		StackSplitRightButton:Disable();
	end
	StackSplitLeftButton:Enable();
end

function BloodOfSargerasMultiPurchase:StackSplitFrame_OnKeyDown(stackSplitFrame,key)
	
	-- Intercept the Backspace and Delete keys since we need to implement 
	-- logic for the Blood of Sargeras vendor.
	if ( key == "BACKSPACE" or key == "DELETE" ) then
		
		if ( stackSplitFrame.typing == 0 or stackSplitFrame.split == (stackSplitFrame.itemIncrement or 1) ) then
			return;
		end
		
		stackSplitFrame.split = floor(stackSplitFrame.split / 10);
		if ( stackSplitFrame.split <= (stackSplitFrame.itemIncrement or 1) ) then
			stackSplitFrame.split = (stackSplitFrame.itemIncrement or 1);
			stackSplitFrame.typing = 0;
			StackSplitLeftButton:Disable();
		else
			StackSplitLeftButton:Enable();
		end
		StackSplitText:SetText(stackSplitFrame.split);
		if ( stackSplitFrame.money == stackSplitFrame.maxStack ) then
			StackSplitRightButton:Disable();
		else
			StackSplitRightButton:Enable();
		end
		
	-- Have to trap for any keys not associated with the StackSplitFrame,
	-- and that aren't related to Confirm, Cancel, etc.; otherwise an error 
	-- will be thrown since we cannot call RunBinding directly in usercode land.
	elseif ( not ( tonumber(numKey) ) and GetBindingAction(key) 
		and key ~= "ENTER" and GetBindingFromClick(key) ~= "TOGGLEGAMEMENU" 
		and key ~= "LEFT" and key ~= "DOWN" and key ~= "RIGHT" and key ~= "UP" ) then
		-- TODO: Find a way around RunBinding protections if possible
		-- Note: This is intentionally an NOOP right now
		
	else
		-- Allow original logic to fire in all other cases.
		self.hooks[StackSplitFrame]["OnKeyDown"](stackSplitFrame, key);
		
	end
	
end

function BloodOfSargerasMultiPurchase:StackSplitFrame_OnChar(self,text)

	if ( text < "0" or text > "9" ) then
		return;
	end

	if ( self.typing == 0 ) then
		self.typing = 1;
		self.split = 0;
	end

	local split = (self.split * 10) + text;
	
	if ( split == self.split ) then
		if( self.split == 0 ) then
			self.split = (self.itemIncrement or 1);
		end
		return;
	end

	if ( split <= self.maxStack ) then
		self.split = split;
		StackSplitText:SetText(split);
		if ( split == self.maxStack ) then
			StackSplitRightButton:Disable();
		else
			StackSplitRightButton:Enable();
		end
		if ( split == (self.itemIncrement or 1) ) then
			StackSplitLeftButton:Disable();
		else
			StackSplitLeftButton:Enable();
		end
	elseif ( split == 0 ) then
		self.split = (self.itemIncrement or 1);
	end
end

function BloodOfSargerasMultiPurchase:StackSplitFrameOkay_Click()

	StackSplitFrame:Hide();
	
	if ( StackSplitFrame.owner ) then
		if (StackSplitFrame.itemIncrement) then
		
			-- If the Stack Split Size doesn't match a purchasable qty, always round
			-- down to the next closest amount (e.g. if it's qty of 3-per, and user
			-- enters 5, then assume 3 and not 6...Can always spend 1 more vs. losing
			-- it unintentionally).
			local mod = StackSplitFrame.split % (StackSplitFrame.itemIncrement or 1);
			if (mod ~= 0) then
				StackSplitFrame.split = StackSplitFrame.split - mod;
			end
			BuyMerchantItem(StackSplitFrame.owner:GetID(), StackSplitFrame.split);
			
		else
			StackSplitFrame.owner.SplitStack(StackSplitFrame.owner, StackSplitFrame.split);
			
		end
	end
	
end


