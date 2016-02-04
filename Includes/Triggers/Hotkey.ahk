Include_Trigger_Hotkey(){
	module_manager.reg("module_hotkey")
}
Class module_hotkey extends module_base_trigger{
	static module_version:= 1.0
	static module_about:="Hotkey is a Trigger for Hotkeys. `nCreated by Electrocret"
	trigger_reg(vhotkeys, Action, trigpriority:=0, Options:=""){
		if(!base.trigger_isreg(this.generateTrigName(vhotkeys,Options)))
		{
			function:=Func("module_Hotkey_trigger")
			;Resets Hotkey
			Hotkey, IfWinActive
			Hotkey, IfWinNotActive
			Hotkey, IfWinExist
			Hotkey, IfWinNotExist
			;Implement Hotkey Options
			if(isobject(Options))
			{
				if(Options.IfWinActive)
				{
					WinActiveTitle:=Options.WinActiveTitle
					WinActiveText:=Options.WinActiveText
					Hotkey, IfWinActive, %WinActiveTitle%, %WinActiveText%
				}
				if(Options.IfWinExist)
				{
					WinExistTitle:=Options.WinExistTitle
					WinExistText:=Options.WinExistText
					Hotkey, ifWinExist, %WinExistTitle%, %WinExistText%
				}
				if(Options.IfWinNotActive)
				{
					WinNotActiveTitle:=Options.WinNotActiveTitle
					WinNotActiveText:=Options.WinNotActiveText
					Hotkey, IfWinNotActive, %WinNotActiveTitle%, %WinNotActiveText%
				}
				if(Options.IfWinNotExist)
				{
					WinNotExistTitle:=Options.WinNotExistTitle
					WinNotExistText:=Options.WinNotExistText
					Hotkey, ifWinExist, %WinNotExistTitle%, %WinNotExistText%
				}
				function.bind(Options)
			}
			Hotkey, %vhotkeys%,%function%
		}
		base.trigger_reg(this.generateTrigName(vhotkeys,Options),Action,trigpriority)
	}
	trigger_unreg(vhotkeys, Action,trigpriority:=0, Options:="")	{
		base.trigger_unreg(this.generateTrigName(vhotkeys,Options),Action,trigpriority)
	}
	generateTrigName(vhotkeys,Options)	{
		output:=vhotkeys
		if(isobject(Options))
		{
			if(Options.IfWinActive)
				output.="#WinActive_" Options.WinActiveTitle "_" Options.WinActiveText
			if(Options.IfWinExist)
				output.="#WinExist_" Options.WinExistTitle "_" Options.WinExistText
			if(Options.IfWinNotActive)
				output.="#WinNotActive_" Options.WinNotActiveTitle "_" Options.WinNotActiveText
			if(Options.IfWinNotExist)
				output.="#WinNotExist_" Options.WinNotExistTitle "_" Options.WinNotExistText
		}
		return output
	}
	trigger_fire(Options,TriggerHotkey){
		/*
		;Fires without generating variants
		
		if(isobject(Options))
			Options.Hotkey:=TriggerHotkey
		else
			Options:=TriggerHotkey
		base.trigger_fire(this.generateTrigName(TriggerHotkey,Options),Options)
		*/
		
		HotkeyVariants:=Array()
		HotkeyVariants.insert(TriggerHotkey)
		ifnotinstring,TriggerHotkey,*
		{
			HotkeyVariants.insert("*" TriggerHotkey)
		}
		ifinstring,TriggerHotkey,$
		{
			StringReplace,hkd,TriggerHotkey,$
			HotkeyVariants.insert("*" hkd)
			HotkeyVariants.insert(hkd)
		}
		ifinstring,TriggerHotkey,>
		{
			Stringreplace,hkd,TriggerHotkey,>
			HotkeyVariants.insert("*" hkd) 
			HotkeyVariants.insert(hkd)
		}
		ifinstring,TriggerHotkey,<
		{
			Stringreplace,hkd,TriggerHotkey,<
			HotkeyVariants.insert("*" hkd)
			HotkeyVariants.insert(hkd)
		}
		ifinstring,TriggerHotkey,~
		{
			Stringreplace,hkd,TriggerHotkey,~
			HotkeyVariants.insert("*" hkd) 
			HotkeyVariants.insert(hkd)
		}
		if(isobject(Options))
			Options.Hotkey:=TriggerHotkey
		else
			Options:=TriggerHotkey
		Loop, % HotkeyVariants.MaxIndex()
		{
			base.trigger_fire(Options,this.generateTrigName(HotkeyVariants[A_Index],Options))
		}
		
		return 1
	}
	trigger_constructor(guiinfo:="")	{
		if(isobject(guiinfo))
		{
			if(guiinfo.vHotkey1 == "")
			{
				module_triggermanager.construct()
			}
			module_triggermanager.construct(guiinfo.vHotkey1)
			return
		}
		module_guitemplate.Hotkeys(A_thisfunc)
	}
	trigger_loader(loadmode,instance,action){
		if(loadmode)
			this.trigger_reg(instance, action)
		else
			this.trigger_unreg(instance,action)
	}
	#include *i %A_ScriptDir%\Generated\Extensions_Hotkeys.ahk
}
module_Hotkey_trigger(Options:="")
{
	module_hotkey.trigger_fire(Options,A_ThisHotkey)
}