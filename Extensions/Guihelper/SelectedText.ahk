selectedtext_hook_module_init(implementedby)
{
	module_dependency.include("Trigger","hotkey")
	module_dependency.module("hotkey")
	module_hotkey.trigger_reg("~LButton","GuiHelper.SelectedText Down",-1)
	module_hotkey.trigger_reg("~LButton UP","GuiHelper.SelectedText Up",-1)
}
Selectedtext_hook_Clipboard_Change(Implementedby, changetype)
{
	getselected:=this.datastore_get("GetSelected","SelectedText",0)
	if(getselected)
	{
		if(getselected == 1)
		{
			this.datastore_set("SelectedText","SelectedText",Clipboard)
			this.datastore_set("GetSelected","SelectedText",2)
			Clipboard:=this.datastore_get("Clipboard","SelectedText")
		}
		else
		{
			this.datastore_set("Clipboard","SelectedText","")
			this.datastore_set("GetSelected","SelectedText",0)
			this.trigger_fire(this.datastore_get("SelectedText","SelectedText"),"SelectedText")
		}
		return 1
	}
}
SelectedText_Get()
{
	this.datastore_set("GetSelected","SelectedText",1)
	this.datastore_set("Clipboard","SelectedText",Clipboard)
	SendInput ^c
}
	;Helper Action that is ran when Mouse LButton is pressed or released.
Action_SelectedText(Action_Info,EventInfo)
{
		static startx
		directive:=eventinfo.directive
		if(directive == "Execute")
		{
			CoordMode, Mouse ,Screen
			if(Action_Info == "Down")
			{
				;Record starting point
				MouseGetPos, startx
			}
			else if(Action_Info == "Up")
			{
				;Calculate endpoint change
				MouseGetPos, x
				ignorekey:=this.datastore_get("IgnoreDragKey","SelectedText","Control"), dragdistance:=this.datastore_get("DragDistance","SelectedText",15),	xdif:=startx-x
				getkeystate keystate, %ignorekey%
				if((xdif<-dragdistance or xdif>dragdistance) And keystate != "D")
					this.SelectedText_Get()
			}
		}
}