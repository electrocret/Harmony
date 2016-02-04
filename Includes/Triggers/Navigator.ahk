Include_Trigger_Navigator(){
module_manager.module_reg("module_navigator")
module_actionmanager.reg("navigator")
}

Class module_navigator extends module_base_trigger{
	static module_version:= 1.0
	static module_about:="Navigator is a trigger that makes menus similar to RadialMenu's Navigator, however it uses Harmony's Built in library in GuiHelper. `nCreated by Electrocret`nInspiration by Learning one (Boris Mudrinić)"
#include *i %A_ScriptDir%\Generated\Extension_Navigator.ahk
	trigger_reg(MenuName, ItemName,Action)	{
		ifinstring, ItemName, .
		{
			StringgetPos, posit,ItemName,.,R
			trigMenuName:=MenuName "." SubStr(ItemName,1,posit)
			StringLower, trigMenuName, trigMenuName
			trigMenuName:=this.module_format_naturalize("Navigator_Menu_" trigMenuName)
			pos:=pos+2
			trigItemName:=SubStr(ItemName,posit)
		}
		else
		{
			trigMenuName:=MenuName
			trigItemName:=ItemName
		}
		base.trigger_reg(trigMenuName "_" trigItemName, Action)
		module_guihelper.menu_add(MenuName,"module_navigator_Menu",ItemName)
	}
	trigger_unreg(MenuName, ItemName, Action)	{
		ifinstring, ItemName, .
		{
			StringgetPos, posit,ItemName,.,R
			trigMenuName:=MenuName "." SubStr(ItemName,1,posit)
			StringLower, trigMenuName, trigMenuName
			trigMenuName:=this.module_format_naturalize("Navigator_Menu_" trigMenuName)
			pos:=pos+2
			trigItemName:=SubStr(ItemName,posit)
		}
		else
		{
			trigMenuName:=MenuName
			trigItemName:=ItemName
		}
		base.trigger_unreg(trigMenuName "_" trigItemName, Action)
		module_guihelper.menu_remove(MenuName,"module_navigator_Menu",ItemName)
	}
	trigger_constructor()	{
		InputBox, MenuName , MenuName, Please Enter the Name of the Menu:
		if(errorlevel == 0)
		{
			InputBox, ItemName , ItemName, Please Enter the Name of the Item:`n(For Submenus separate by Periods. Ex: Submenu1.Submenu2.ItemName )
			if(errorlevel == 0)
				module_triggermanager.construct(MenuName "." ItemName)
		}
		module_triggermanager.construct()
		return
	}
	trigger_loader(loadmode,instance,action)	{
		StringgetPos, posit,instance,.
		MenuName:=SubStr(instance,1,posit)
		posit:=posit+2
		ItemName:=:=SubStr(instance,posit)
		if(loadmode)
			this.trigger_reg(MenuName,ItemName,Action)
		else
			this.trigger_unreg(MenuName,ItemName,Action)
	}
	module_trigger_display(instance)	{
		stringreplace, instance,instance,.,-
		return instance
	}
	action(Action_Info, EventInfo)	{
		directive:=eventinfo.directive
		if(directive == "Execute")
		{
			Mousegetpos, x,y
			module_guihelper.menu_show(Action_Info,x,y)
			return			
		}
		if(directive == "Wizard")
		{
			InputBox, MenuName , MenuName, What is the name of the Menu you would like to show?
			if(errorlevel == 0)
				module_actionmanager.wizard(MenuName)
			module_actionmanager.wizard()
		}
		if(directive == "Initialize")
			return "Wizard"
				
	}
}
module_navigator_Menu(ItemName, ItemPos, MenuName){
	triggervar:={ItemName: ItemName, ItemPos: ItemPos, MenuName: MenuName}
	module_navigator.trigger_fire(triggervar,MenuName "_" ItemName)
}