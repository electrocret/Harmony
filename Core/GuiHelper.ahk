class module_guihelper extends module_base_trigger{
static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/GuiHelper.ahk"
	static module_version:=1.0
	static module_initialize_level:=90
	static module_about:="GuiHelper Creates a standard interface for Script Additions to use to maintain consistency and reduce conflicts. It also contains templating functions used by GuiTemplate`nCreated by Electrocret"
	static guinum:=1,GuiInfo:=Array(),ReturnFunction:="",AdditionalVar1:="",AdditionalVar2:="",GuiID,templatelock:=0,guioptions
	
	#include *i %A_ScriptDir%\Generated\Extension_guihelper.ahk
	module_init()	{
		this.datastore_set_Default_Datastore("this")
		this.menu_add("tray","module_guihelper_tray_handler","Suspend","Reload", "Exit")
		OnClipboardChange("module_guihelper_clipchange", -1)
		OnExit("module_guihelper_exit",-1)
	}
	suspend(state:=2) {
		if(this.hook(A_thisFunc,state))
			return  this.hook_value(A_thisFunc)
		if (state = 0 or state = "off") {
		this.tray_uncheck("module_guihelper_tray_handler","Suspend")
		this.tray_icon()
		Suspend, off
		}
		else if (state = 1 or state = "on") {
		this.tray_check("module_guihelper_tray_handler","Suspend")
			this.tray_icon("suspended")
			Suspend, on
		}
		else if (state = 2 or state = "toggle") {
			if (A_IsSuspended = 1)
				this.suspend(0)
			else
				this.suspend(1)
			}
	}
	Clipboard_set(newclipboard)	{
		if(this.hook(A_thisFunc,newclipboard))
			return  this.hook_value(A_thisFunc)
		this.Clipboard_ignoreChange(1)
		Clipboard:=newclipboard
	}
	Clipboard_ignoreChange(times)	{
		if(this.hook(A_thisFunc,times))
			return  this.hook_value(A_thisFunc)
			ignorenextchange:=this.datastore_Get("IgnoreNextChange","Clipboard",0)
			ignorenextchange+=times
			this.datastore_Set("IgnoreNextChange","Clipboard",ignorenextchange)
	}
	Clipboard_Change(type)	{
		Critical, On
		if(this.hook(A_thisFunc,type))
			return  this.hook_value(A_thisFunc)
		this.datastore_Set("Clipboard","Clipboard",Clipboard)
		this.datastore_set("ClipboardAll","Clipboard",ClipboardAll)
		Critical, Off
		ignorenextchange:=this.datastore_Get("IgnoreNextChange","Clipboard",0)
		if(ignorenextchange == 0)
			this.trigger_fire(Clipboard,"ClipboardChange","ClipboardChange_" type,"ClipboardChange_always")
		else
		{
			ignorenextchange:=ignorenextchange > 0 ? ignorenextchange-- : 0
			this.datastore_Set("IgnoreNextChange","Clipboard",ignorenextchange)
			this.trigger_fire(Clipboard,"ClipboardChange_always")
		}
	}
	tray_default(item)	{
		if(this.hook(A_thisFunc,item))
			return  this.hook_value(A_thisFunc)
		traymenu:=this.menu_store("tray","")
		traymenu.tray_default:=item
		this.menu_store("tray","",1,traymenu)		
		item:=item == "" ? "Suspend" : item
		Menu, Tray, default, %item%
	}
	tray_icon(IconState:="")	{
		if(this.hook(A_thisFunc,IconState))
			return  this.hook_value(A_thisFunc)
		icondir:=module_manager.datastore_Get("Icons","Core_Directory")
		ifexist, %A_ScriptDir%\resources\icons\%IconState%.ico
			Menu, Tray, Icon, %icondir%\%IconState%.ico,,1
		else ifexist, %A_ScriptDir%\resources\icons\icon.ico
			Menu, Tray, Icon, %icondir%\icon.ico,,1
		traymenu:=this.menu_store("tray","")
		traymenu.tray_icon:=IconState
		this.menu_store("tray","",1,traymenu)			
	}
	menu_generate(RootMenuName)	{
		if(this.hook(A_thisFunc,RootMenuName))
			return  this.hook_value(A_thisFunc)
		if(RootMenuName == "tray" and module_manager.initialize_level == -1)
		{
			MenuArray:=this.menu_store(RootMenuName,"")
			Menu, %RootMenuName%, DeleteAll
			Loop % MenuArray.MaxIndex()
			{
				submenus:=[RootMenuName]
				menugroup:=MenuArray[A_Index]
				function:=Func(menugroup.Function)
				functionname:=menugroup.Function
				Loop % menugroup.items.MaxIndex()
				{
					fullitemtree:=menugroup.items[A_Index]
					item:=menugroup.items[A_Index]
					MenuID:=RootMenuName
					ifinString, item, .
					{
						Levels:=Array()
						MenuLevels:=Array()
						MenuLevel:=RootMenuName
						Loop, Parse, item,.
						{
							MenuLevels.push(MenuLevel)
							Levels.push(A_LoopField)
							StringLower, MenuLevel, MenuLevel
							MenuLevel:=MenuLevel "." A_LoopField
						}
						pMenuID:=RootMenuName
						Loop, % MenuLevels.MaxIndex()
						{
							levelid:=MenuLevels.length()-A_Index
							levelid++
							MenuID:=MenuLevels[levelid] == RootMenuName ? RootMenuName : this.module_format_naturalize(functionname "_" MenuLevels[levelid])
							item:=Levels[levelid]
							testlvl:=MenuLevels[levelid] 
							if(levelid == MenuLevels.length())
							{
								Menu, %MenuID%, Add, %item%, %function%
							}
							if(!submenus.contains(pMenuID))
							{
								this.submenus.push(pMenuID)
								Menu, %menuID%, Add, %item%, %function%:%pMenuID%
							}
							pItem:=item
							pMenuID:=MenuID
						}
						item:=Levels[Levels.MaxIndex()]
						MenuID:=this.module_format_naturalize(functionname "_" MenuLevels[Levels.MaxIndex()])
					}
					else
					{
						Menu, %MenuID%, Add, %item%, %function%
					}
					if(menugroup.checks.contains(fullitemtree))
						Menu, %MenuID%, Check, %item%
					if(menugroup.disables.contains(fullitemtree))
						Menu, %MenuID%, Disable, %item%
				}
				if(MenuArray.MaxIndex() != A_Index)
					Menu, %RootMenuName%, Add,,
			}
			if(RootMenuName == "tray")
			{
				if(!this.log_isLevel("debug"))
					Menu, tray, NoStandard 
				else
					Menu, tray, Standard 
				this.tray_icon(MenuArray.tray_icon)
				this.tray_default(MenuArray.tray_default)
				version:=module_manager.datastore_Get("Version","Core")
				Menu, Tray, Tip, Harmony v%version%
			}
		}
	}
	menu_store(MenuName,Function, mode:=0, tostore:="")	{
		if(this.hook(A_thisFunc,MenuName,Function,mode,tostore))
			return  this.hook_value(A_thisFunc)
		static menus:=Array()
		if(Function == "")
		{
			if(mode == 0)
				return menus[MenuName]
			if(mode == -1)
				menus[MenuName]:=""
			if(mode == 1)
				menus[MenuName]:=tostore
				return
		}
		selectedmenu:=menus[MenuName] == "" ? Array() : menus[MenuName]
		Loop % selectedmenu.MaxIndex()
		{
			if(selectedmenu[A_Index].function == function)
			{
				if(mode == 0)
					return selectedmenu[A_Index]
				if(mode == 1)
				{
					selectedmenu[A_Index]:=tostore
					menus[MenuName]:=selectedmenu
					return
				}
				if(mode == -1)
				{
					selectedmenu.removeAt(A_Index)
					menus[MenuName]:=selectedmenu
					return
				}
			}
		}
		if(mode)
		{
			selectedmenu.push(tostore)
			menus[MenuName]:=selectedmenu
			return
		}
		return {function: Function, checks: Array(), disables: Array(), Items: Array()}
	}
	menu_add(MenuName,Function,Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				continue
			if(!menugroup.items.contains(item))
				menugroup.items.push(item)
		}
		if(this.hook_value(A_thisFunc) != "")
			return this.hook_value(A_thisFunc)
		this.menu_store(MenuName,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_delete(MenuName,Function,Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				continue
			if(menugroup.items.contains(item))
			{
				menugroup.items.removeAt(menugroup.items.indexOf(item))
				if(menugroup.checks.contains(item))
					menugroup.checks.removeAt(menugroup.checks.indexOf(item))
				if(menugroup.disables.contains(item))
					menugroup.disables.removeAt(menugroup.disables.indexOf(item))
			}
		}
		
		if(menugroup.items.length() == 0)
			this.menu_store(menuname,Function,-1)
		else
			this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_check(MenuName,Function, Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				continue
			if(menugroup.items.contains(item) and !menugroup.checks.contains(item))
			{
				menugroup.checks.push(item)
			}
		}
		if(this.hook_value(A_thisFunc) != "")
			return this.hook_value(A_thisFunc)
		this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_uncheck(MenuName,Function, Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				continue
			if(menugroup.items.contains(item) and menugroup.checks.contains(item))
				menugroup.checks.removeAt(menugroup.checks.indexOf(item))
		}
		if(this.hook_value(A_thisFunc) != "")
			return this.hook_value(A_thisFunc)
		this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_disable(MenuName,Function, Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				continue
			if(menugroup.items.contains(item) and !menugroup.disables.contains(item))
				menugroup.disables.push(item)
		}
		if(this.hook_value(A_thisFunc) != "")
			return this.hook_value(A_thisFunc)
		this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_enable(MenuName,Function, Items*)	{
		menugroup:=this.menu_store(MenuName, Function)
		for index,Item in Items
		{
			this.menu_item_clean(item)
			if(this.hook(A_thisFunc,MenuName,Function,Item))
				return  this.hook_value(A_thisFunc)
			if(menugroup.items.contains(item) and menugroup.disables.contains(item))
				menugroup.disables.removeAt(menugroup.disables.indexOf(item))
		}
		if(this.hook_value(A_thisFunc) != "")
			return this.hook_value(A_thisFunc)
		this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_rename(MenuName, Function, MenuItemName, NewItem:="")	{
		if(this.hook(A_thisFunc,MenuName,Function,MenuItemName,NewItem))
			return  this.hook_value(A_thisFunc)
		menugroup:=this.menu_store(MenuName, Function)
		if(menugroup.items.contains(MenuItemName))
		{
			index:=menugroup.items.indexOf(MenuItemName)
			menugroup.items.removeAt(index)
			menugroup.items.insertAt(index,NewItem)
			if(menugroup.checks.contains(MenuItemName))
			{
				index:=menugroup.checks.indexOf(MenuItemName)
				menugroup.checks.removeAt(index)
				menugroup.checks.insertAt(index,NewItem)
			}
			if(menugroup.disables.contains(MenuItemName))
			{
				index:=menugroup.disables.indexOf(MenuItemName)
				menugroup.disables.removeAt(index)
				menugroup.disables.insertAt(index,NewItem)
			}
		}
		this.menu_store(menuname,Function,1,menugroup)
		this.menu_generate(menuname)
	}
	menu_DeleteAll(MenuName,Function:="")	{
		if(this.hook(A_thisFunc,MenuName,Function))
			return  this.hook_value(A_thisFunc)
		this.menu_store(MenuName,function,-1)
		this.menu_generate(MenuName)
	}
	menu_isMenu(MenuName)	{
		if(this.hook(A_thisFunc,MenuName))
			return  this.hook_value(A_thisFunc)
		return isobject(this.menu_store(MenuName,""))
	}
	menu_show(MenuName,x:="",y:="")	{
		if(this.hook(A_thisFunc,MenuName,x,y))
			return  this.hook_value(A_thisFunc)
		if(this.menu_isMenu(MenuName))
			Menu, %MenuName%, show, %x%, %y%
		
	}
	menu_item_clean(byref item)	{
		While(InStr(item, ..))
		{
			StringReplace, item,item,..,.,All
		}
	
	}
	getGuiID(GuiName)	{
		this.hook(A_thisFunc,GuiName)
		GuiNam:=this.module_format_naturalize(GuiName)
		if(this[ GuiNam]=="")
		{
			newguiid:=this.guinum
			this.guinum++
			this[ GuiNam]:=newguiid
			return newguiid
		}
		return this[GuiNam]
	}
	hasGuiID(GuiName)	{
		this.hook(A_thisFunc,GuiName)
		GuiNam:=this.module_format_naturalize(GuiName)
		return this[ GuiNam]!=""
	}
	Template_Submit()	{
		this.templatelock:=0
		guiid:=this.guiID
		gui,%guiID%:submit
	}
	Template_return(ControlName)	{
		if(this.templatelock)
			this.Template_Submit()
		GuiInfo:=this.GuiInfo,		GuiInfo.GUIAction:=ControlName
		this.Template_exec(this.ReturnFunction,GuiInfo,this.AdditionalVar1,this.AdditionalVar2)
	}
	Template_exec(ReturnFunction,GuiInfo:="±",AdditionalVar1:="±",AdditionalVar2:="±")	{
		this.module_func_exec(ReturnFunction,GuiInfo,AdditionalVar1,AdditionalVar2)
	}
	template_init(ReturnFunction,TemplateFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:="")	{
		this.hook(A_thisFunc,ReturnFunction,TemplateFunction,GuiInfo,AdditionalVar1,AdditionalVar2)
		if(isfunc(ReturnFunction))
		{
			if(!this.templatelock)
			{
				if(isobject(this.guioptions))
				{
					For key, val in this.guioptions
						GuiInfo[key]:=val
				}
				this.guioptions:="", this.ReturnFunction:=ReturnFunction, this.GuiInfo:=GuiInfo, this.AdditionalVar1:=AdditionalVar1, this.AdditionalVar2:=AdditionalVar2
			}
			StringgetPos, pos,TemplateFunction,.,R
			if(!ErrorLevel)
			{
				pos:=pos+2
				GuiInfo.Template:=SubStr(TemplateFunction,pos)
			}
			else
				GuiInfo.Template:=TemplateFunction
			output:=!this.hasGuiID(TemplateFunction)
			if(!this.templatelock)
				this.GuiID:=This.getguiID(TemplateFunction)
			return output
		}
		else
			this.log_error(A_thisFunc,"Template GUI attempted with, but ReturnFunction is not valid - " ReturnFunction)
	}
	Template_ID(TemplateFunction)	{
		this.hook(A_thisFunc,TemplateFunction)
		return This.getguiID(TemplateFunction)
	}
	Template_Var(ControlID,ControlName)	{
		this.hook(A_thisFunc,ControlID,ControlName)
		this.GuiInfo["v" ControlName]:=ControlID
	}
	Template_Show(DefaultWidth,DefaultHeight,DefaultWindowTitle:="")	{
		if(this.templatelock)
			return
		this.hook(A_thisFunc,DefaultWidth,DefaultHeight,DefaultWindowTitle)
		this.templatelock:=1,		guiID:=this.guiid,		Windowtitle:=this.GuiInfo.Windowtitle == "" ? DefaultWindowTitle : this.GuiInfo.Windowtitle, WindowWidth:=this.GuiInfo.WindowWidth is number ? this.GuiInfo.WindowWidth : DefaultWidth, WindowHeight:=this.GuiInfo.WindowHeight is number ? this.GuiInfo.WindowHeight : DefaultHeight
		gui, %guiID%: +Labelmodule_guihelper_
		gui, %guiID%:Show, w%windowwidth% h%windowheight% Center, %WindowTitle%
	}
	Template_Customize(byref ControlID,ControlName,DefaultName:="",DefaultHide:=0)	{
		if(this.templatelock)
			return
		GuiID:=this.GuiID
		GuiControl, %guiID%:Show, ControlID
		GuiControl, %guiID%:Enable, ControlID
		ControlText:=this.GuiInfo[ControlName] != "" ? this.GuiInfo[ControlName]: DefaultName
		if(this.log_isLevel("debug"))
			ControlText:=this.GuiInfo[ControlName] == "" and ControlText == DefaultName ? DefaultName : ControlName
		this.hook(A_thisFunc,ControlID,ControlName,DefaultName,DefaultHide)
		if ControlName contains Dropdownlist,ListBox,DateTime,Tab2
		{
			if(substr(ControlText,1,1) != "|")
				ControlText:="|" ControlText
			GuiControl, %guiID%:Choose, ControlID, 0
		}
		if(this.GuiInfo[ControlName] == "" and DefaultName == "" and DefaultHide)
		{
			GuiControl, %guiID%:Hide, ControlID
		}
		Guicontrol,%guiID%:,ControlID, %ControlText%
		if(this.GuiInfo[ControlName "_Choose"] !="")
		{
			param:=this.GuiInfo[ControlName "_Choose"]
			GuiControl, %guiID%:Choose, ControlID, %param%
		}
		if(this.GuiInfo[ControlName "_ChooseString"] !="")
		{
			param:=this.GuiInfo[ControlName "_ChooseString"] 
			GuiControl, %guiID%:ChooseString, ControlID, %param%
		}
		if(this.GuiInfo[ControlName "_Move"] !="")
		{
			param:=this.GuiInfo[ControlName "_Move"]
			GuiControl, %guiID%:Move, ControlID, %param%
		}
		if(this.GuiInfo[ControlName "_MoveDraw"] !="")
		{
			param:=this.GuiInfo[ControlName "_MoveDraw"]
			GuiControl, %guiID%:MoveDraw, ControlID, %param%
		}
		if(this.GuiInfo[ControlName "_Text"] !="")
		{
			param:=this.GuiInfo[ControlName "_Text"] 
			GuiControl, %guiID%:Text, ControlID, %param%
		}
		if(this.GuiInfo[ControlName "_Disable"] == 1)
		{
			GuiControl, %guiID%:Disable, ControlID
		}
		if(this.GuiInfo[ControlName "_Hide"] == 1)
		{
			GuiControl, %guiID%:Hide, ControlID
		}
		if(this.GuiInfo[ControlName "_Focus"] == 1)
		{
			GuiControl, %guiID%:Focus, ControlID
		}
	}
	Template_Gui_Customize(GuiOptions)	{
		this.GuiOptions:=isobject(GuiOptions)?guioptions: ""
	}
	Notifier_aggregate(AgglockvalOrFunc:=0)	{
		static aggregatefuncs:=Array(),agglock:=1
		if(isfunc(AgglockvalOrFunc))
		{
			if(agglock)
			{
				if(!aggregatefuncs.contains(AgglockvalOrFunc))
					aggregatefuncs.push(AgglockvalOrFunc)
					return 1
			}
			this.module_func_exec(AgglockvalOrFunc)
			return 0
		}
		if(AgglockvalOrFunc == "")
			return agglock
		if(agglock == AgglockvalOrFunc)
		{
			agglock:=1
			loop % aggregatefuncs.MaxIndex()
				this.module_func_exec(aggregatefuncs[A_Index])
			aggregatefuncs:=Array()
		}
		if(agglock == 1 and AgglockvalOrFunc == 0)
		{
			agglock:=2
			return 2
		}
		return 0
	}
	OnMessage(MsgNumber ,Action)	{
		OnMessage(MsgNumber,"module_guihelper_onmessage")
		base.trigger_reg("message_" MsgNumber,Action)
	}
	OnExit(ExitReason,Action){
	
		return this.trigger_reg("exit_" ExitReason, Action)
	}
	OnExit_Code(ExitCode,Action){
		return this.trigger_reg("exit_code_" ExitCode, Action)
	}
	OnClipboardChange(Action,type:="")	{
		if(type =< 2 or type >= 0 or type == "always")
			return base.trigger_reg("ClipboardChange_" type, Action)
		return base.trigger_reg("ClipboardChange", Action)
	}
	core_file()
	{
		return A_LineFile
	}
}
module_guihelper_clipchange(type){
	module_guihelper.Clipboard_Change(type)
}
module_guihelper_tray_handler(ItemName, ItemPos, MenuName){
		if(ItemName == "Suspend")
			module_guihelper.suspend()
		if(ItemName == "Reload")
			reload
		if(ItemName == "Exit")
			ExitApp
}
module_guihelper_Close(GuiHwnd) {
	module_guihelper.Template_return("GuiClose")
}
module_guihelper_Escape(GuiHwnd) { 
return module_guihelper.trigger_fire(GuiHwnd,"GuiEscape")
}
module_guihelper_Size(GuiHwnd) { 
return module_guihelper.trigger_fire(GuiHwnd,"GuiSize")
}
module_guihelper_ContextMenu(GuiHwnd) { 
return module_guihelper.trigger_fire(GuiHwnd,"GuiContextMenu")
}
module_guihelper_DropFiles(GuiHwnd) { 
return module_guihelper.trigger_fire(GuiHwnd,"GuiDropFiles")
}
module_guihelper_exit(exitreason,exitcode){
	module_guihelper.trigger_fire({exitreason:exitreason,exitcode:exitcode},"exit_" exitreason,"exit_code_" exitcode,"exit_any")
}
module_guihelper_onmessage(wParam, lParam, MsgNumber, Hwnd){
	EventData:={wParam:wParam,lParam:lParam,MsgNumber:MsgNumber,Hwnd:Hwnd}
	module_guihelper.trigger_fire(EventData,"message_" MsgNumber)
}