Include_Trigger_Hotstring(){
module_dependency.include("Hotkey","Trigger")
module_manager.reg("module_hotstring")
}
Class module_hotstring extends module_base_trigger {
	static module_version:= 1.0
	static module_about:="Hotstring is a Trigger for Hotstrings. `nCreated by Electrocret"
	static charactercount:=0
	static inputtext
	static inputtextwithoutlastchar
	static keymodifiers:="~$"
	static endkeys:="Space|Enter|Return|Tab|NumpadEnter|NumpadDot|-|{|}|[|]|(|)|:|;|'|/|\|,|.|?|!"
	static clearkeys:="Left|Right|Up|Down|Home|End|RButton|LButton"
	static backspacekeys:="BS"
	#include *i %A_ScriptDir%\Generated\Extensions_Hotstrings.ahk
	module_init()	{
		module_dependency.module("module_hotkey")
		;Gets lists of keys with special handling procedures
		keymodifiers:=this.keymodifiers,	endk:=this.endkeys,	cleark:=this.clearkeys,	backspacek:=this.backspacekeys,	keyavoidance := endk "|" cleark "|" backspacek
		Stringreplace, keyavoidance,keyavoidance,|,`,,All
			;Registers main keyboard hotkeys
			Loop, 94
			{
				c := Chr(A_Index + 32)
				If A_Index not between 33 and 58
					if c not in %keyavoidance%
					{
						module_hotkey.reg( keymodifiers c, "Hotstring " c,-1)
						If A_Index between 65 and 90
						{
							StringUpper, uc,c
							module_hotkey.reg( keymodifiers "+" c, "Hotstring " uc,-1)
						}	
					}
			}
			;registers numpad hotkeys
			e = 0|1|2|3|4|5|6|7|8|9|Div|Mult|Add|Sub|Dot
			Loop, Parse, e, |
			{
				if a_loopfield not in %keyavoidance%
				{
					naturalized:=a_loopfield == "Div" ? "/" : a_loopfield == "Mult" ? "*" : a_loopfield == "Add" ? "+" : a_loopfield == "Dot" ? "." : a_loopfield
					module_hotkey.reg( keymodifiers "Numpad" A_loopfield, "Hotstring " naturalized,-1)
				}
			}
			;Register Clear Hotkeys
			Loop,parse,cleark,|
				module_hotkey.reg(keymodifiers A_Loopfield, "Hotstring CLEAR",-1)
			
			;Backspace
			Loop,parse, backspacek,|
				module_hotkey.reg(keymodifiers A_Loopfield, "Hotstring BS",-1)
		
			;EndKeys
			Loop, Parse, endk, |
				module_hotkey.reg(keymodifiers A_loopfield, "Hotstring END " A_Loopfield,-1)	
	}
	trigger_reg(Hotstrin,Action,options:="")	{
		opts:=""
		ifinstring, options, *
			opts.="*¶"
		base.trigger_reg(opts Hotstrin,Action)
		return 
	}
	trigger_unreg(Hotstrin,Action,options:="")	{
		opts:=""
		ifinstring, options, *
			opts.="*¶"
		base.trigger_unreg(opts Hotstrin,Action)
	}
	checkinput(Action_Info)	{
		
		if Action_Info contains BS
		{
			if(this.charactercount>0)
				this.charactercount--
			inputtxt:=this.inputtext
			stringtrimright, inputtxto,inputtxt,1
			this.inputtext:=inputtxto
		}
		else if Action_Info contains CLEAR
			this.charactercount:=0, this.inputtext:="", this.inputtextwithoutlastchar:=""
		else
		{
			this.charactercount++
			if Action_Info contains END
				Stringtrimleft, char, Action_Info, 4
			else
				char=%Action_Info%
			this.inputtextwithoutlastchar:=this.inputtext
			this.inputtext.=char	
			this.trigger_fireinput(this.inputtext,this.inputtext,this.charactercount,"*¶")	
			if Action_Info contains END
			{
				inputtxt:=this.inputtext,	hswithoutend:=this.inputtextwithoutlastchar,charcount:=this.charactercount
				this.inputtext:="",	this.inputtextwithoutlastchar:="",	this.charactercount:=0
				this.trigger_fireinput(inputtxt,hswithoutend,charcount)
				this.trigger_fireinput(hswithoutend,hswithoutend,charcount)
			}
		}	
	}
	trigger_fireinput(inputtext, inputtxtwoend, charcount, options:="")	{
		if(this.trigexist(options inputtext))
		{
		
			this.charactercount:=0
			sendinput {BS %charcount%}
			this.trigger_fire(inputtxtwoend,options inputtext)
		}	
		
	}
	action(Action_Info, EventInfo)	{
		directive:=eventinfo.directive
		if( directive ==  "Execute")
		{
			this.checkinput(Action_Info)
		}
	}
	trigger_constructor()	{
		InputBox, string , Hotstring, Please Enter Hotstring:
		if(errorlevel == 0)
			module_triggermanager.construct(string)
		else
			module_triggermanager.construct()
		return
	}
	trigger_loader(loadmode,instance,action)	{
		if(loadmode)
			this.trigger_reg(instance,action)
		else
			this.trigger_unreg(instance,action)
	}

}