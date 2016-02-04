
/*
template(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:="")
{
	static ;Static variables to hold controller IDs
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID()
		;Initialize Menu Here - Use standard AHK Gui Creation with "%guiID%:Add" here where each component has a static ControllerID Variable, and buttons have labels that follow label naming standard "template_<Templatename>_<ControllerName>:"
		
	}
	;Customizes Menu Contents Here using module_guihelper.Template_Customize(<ControllerID>,<ControllerName>)
	
	module_guihelper.Template_Show(<Default Window WIdth>,<Default Window Height>,<Default Window Title>)
	return
	;Menu Controller Labels here
	template_<Templatename>_<ControllerName>:
	module_guihelper.Template_Submit() ;Menu Submit
	module_guihelper.Template_Var(<ControllerID>,<Controller Name>) ;Store any important controller values
	module_guihelper.Template_return(<ControllerName>);Template completed. returns GuiInfo to the Return function
	return
	
bare_template(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:="")
{
	static ;Static variables to hold controller IDs
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID()
		;Initialize Menu Here - Use standard AHK Gui Creation with "%guiID%:Add" here where each component has a static ControllerID Variable, and buttons have labels that follow label naming standard "template_<Templatename>_<ControllerName>:"
		
	}
	;Customizes Menu Contents Here using module_guihelper.Template_Customize(<ControllerID>,<ControllerName>)
	
	
	;Show Menu
	module_guihelper.Template_Show(<Default Window WIdth>,<Default Window Height>,<Default Window Title>)
	return
}
*/




class module_guitemplate extends module_base{
static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/GuiTemplate.ahk"
#include *i %A_ScriptDir%\Generated\Extension_guitemplate.ahk
	static module_version:= 1.0
	static module_about:="GuiTemplate contains functions that contain reusable Gui Templates.`nCreated by Electrocret"
OneButtonDropdown(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1, sbutton, sdropdownlist1
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		;Initialize Menu 
		Gui, %guiID%:Add, DropDownList, x12 y30 w130 h20 R10 Sort vsdropdownlist1
		Gui, %guiID%:Add, GroupBox, x2 y10 w150 h50 vsgroupbox1, Select
		Gui, %guiID%:Add, Button, x12 y70 w130 h30 gtemplate_dropdown_Button1 vsbutton , Select
	}
	;Customizes Menu Contents
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1")
	module_guihelper.Template_Customize(sbutton,"Button1")
	module_guihelper.Template_Customize(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_Show(163,116,"Select")
	return
	template_dropdown_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button1")
	return	
}
TwoButtonDropdown(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sbutton1,sbutton2,sdropdownlist1 ;Static variables to hold controller IDs
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		Gui,  %guiID%:Add, GroupBox, x12 y10 w210 h50 vsgroupbox1, GroupBox1
		Gui,  %guiID%:Add, DropDownList, x22 y30 w190 h20 R10 vsdropdownlist1 Sort, DropDownList1
		Gui,  %guiID%:Add, Button, x12 y70 w100 h30 vsbutton1 gTemplate_TwoButtonDropdown_Button1, Button1
		Gui,  %guiID%:Add, Button, x122 y70 w100 h30 vsbutton2 gTemplate_TwoButtonDropdown_Button2, Button2
	}
	;Customizes Menu Contents Here using module_guihelper.Template_Customize(<ControllerID>,<ControllerName>)
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1")
	module_guihelper.Template_Customize(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_Customize(sbutton1,"Button1")
	module_guihelper.Template_Customize(sbutton2,"Button2")
	module_guihelper.Template_Show(236,113,"Select")
	return
	Template_TwoButtonDropdown_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button1")
	return
	Template_TwoButtonDropdown_Button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button2")
	return
}
manager(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1, sbutton1, sbutton2, sbutton3, sbutton4, slistbox1	;ControlID Holder
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		;Initialize Menu
		Gui, %guiID%:Add, GroupBox, x12 y10 w430 h130 vsgroupbox1 , GroupBox
		Gui, %guiID%:Add, ListBox, x22 y30 w410 h100 Sort vslistbox1, ListBox1
		Gui, %guiID%:Add, Button, x12 y150 w100 h30 gtemplate_manager_button1 vsbutton1, Button1
		Gui, %guiID%:Add, Button, x122 y150 w100 h30 gtemplate_manager_button2 vsbutton2, Button2
		Gui, %guiID%:Add, Button, x232 y150 w100 h30 gtemplate_manager_button3 vsbutton3 , Button3
		Gui, %guiID%:Add, Button, x342 y150 w100 h30 gtemplate_manager_button4 vsbutton4, Button4
	}
	;Customizes Menu Contents
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1","Manager")
	module_guihelper.Template_Customize(slistbox1,"ListBox1")
	module_guihelper.Template_Customize(sbutton1,"Button1","",1)
	module_guihelper.Template_Customize(sbutton2,"Button2","",1)
	module_guihelper.Template_Customize(sbutton3,"Button3","",1)
	module_guihelper.Template_Customize(sbutton4,"Button4","",1)
	module_guihelper.Template_Show(457,195,"Manager")
	return
	template_manager_button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(slistbox1,"ListBox1")
	module_guihelper.Template_return("Button1")
	return	
	template_manager_button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(slistbox1,"ListBox1")
	module_guihelper.Template_return("Button2")
	return	
	template_manager_button3:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(slistbox1,"ListBox1")
	module_guihelper.Template_return("Button3")
	return	
	template_manager_button4:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(slistbox1,"ListBox1")
	module_guihelper.Template_return("Button4")
	return	
}
ThreeButtonDropdown(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sbutton1,sbutton2,sbutton3,sdropdownlist1 ;Static variables to hold controller IDs
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		;Initialize Menu Here - Use standard AHK Gui Creation with "%guiID%:Add" here where each component has a static ControllerID Variable, and buttons have labels that follow label naming standard "template_<Templatename>_<ControllerName>:"
		Gui, %guiID%:Add, GroupBox, x2 y10 w230 h100 vsgroupbox1 , Select
		Gui, %guiID%:Add, DropDownList, x12 y30 w210 h20 Sort vsdropdownlist1 R10, DropDownList1
		Gui, %guiID%:Add, Button, x12 y60 w100 h30 vsbutton1 gtemplate_threebuttondropdown_button1, Button1
		Gui, %guiID%:Add, Button, x122 y60 w100 h30 vsbutton2 gtemplate_threebuttondropdown_button2, Button2
		Gui, %guiID%:Add, Button, x2 y120 w230 h30 vsbutton3 gtemplate_threebuttondropdown_button3, Button3
	}
	;Customizes Menu Contents Here using module_guihelper.Template_Customize(<ControllerID>,<ControllerName>)
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1")
	module_guihelper.Template_Customize(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_Customize(sbutton1,"Button1")
	module_guihelper.Template_Customize(sbutton2,"Button2")
	module_guihelper.Template_Customize(sbutton3,"Button3")
	;Show Menu
	module_guihelper.Template_Show(241,161,"Select")
	return
	template_threebuttondropdown_button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button1")
	return
	template_threebuttondropdown_button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button2")
	return
	template_threebuttondropdown_button3:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button3")
	return
}
editor(ReturnFunction,GuiInfo,AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sbutton1,sbutton2,sbutton3,sbutton4,sedit1
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		Gui, %guiID%:Add, GroupBox, x12 y10 w430 h180 vsgroupbox1, GroupBox1
		Gui, %guiID%:Add, Button, x12 y200 w100 h30 vsbutton1 gtemplate_editor_Button1, Button1
		Gui, %guiID%:Add, Button, x342 y200 w100 h30 vsbutton4 gtemplate_editor_Button4, Button4
		Gui, %guiID%:Add, Edit, x22 y30 w410 h150 +Wrap vsedit1, Edit1
		Gui, %guiID%:Add, Button, x232 y200 w100 h30 vsbutton3 gtemplate_editor_Button3, Button3
		Gui, %guiID%:Add, Button, x122 y200 w100 h30 vsbutton2 gtemplate_editor_Button2, Button2
	}
	
	module_guihelper.Template_Customize(sedit1,"Edit1","")
	module_guihelper.Template_Customize(sgroupbox1,"Groupbox1","Edit")
	module_guihelper.Template_Customize(sbutton1,"Button1","",1)
	module_guihelper.Template_Customize(sbutton2,"Button2","",1)
	module_guihelper.Template_Customize(sbutton3,"Button3","",1)
	module_guihelper.Template_Customize(sbutton4,"Button4","",1)
	module_guihelper.Template_Show(454,243,"Editor")
	return
	template_editor_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button1")
	return
	template_editor_Button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button2")
	return
	template_editor_Button3:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button3")
	return
	template_editor_Button4:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button4")
	return
}

Hotkeys_Basic(ReturnFunction,GuiInfo:="",AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sbutton1,sbutton2,shotkey1,scheckbox1
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		Gui, %guiID%:Add, GroupBox, x12 y10 w120 h90 vsgroupbox1, Hotkey
		Gui, %guiID%:Add, Hotkey, x22 y30 w100 h30 vshotkey1 , 
		Gui, %guiID%:Add, CheckBox, x22 y60 w100 h30 vscheckbox1, Windows Key
		Gui, %guiID%:Add, Button, x22 y110 w100 h30 vsbutton1 gTemplate_Hotkeys_Basic_Button1, Advanced
		Gui, %guiID%:Add, Button, x22 y150 w100 h30 vsbutton2 gTemplate_Hotkeys_Basic_Button2, Done
	}
	module_guihelper.Template_Customize(shotkey1,"Hotkey1","")
	module_guihelper.Template_Customize(scheckbox1,"Checkbox1","Windows Key")
	module_guihelper.Template_Customize(sgroupbox1,"Groupbox1","Hotkey")
	module_guihelper.Template_Customize(sbutton1,"Button1","",1)
	module_guihelper.Template_Customize(sbutton2,"Button2","Done")
	module_guihelper.Template_Show(145,195,"Hotkey")
	return
	Template_Hotkeys_Basic_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(shotkey1,"Hotkey1")
	module_guihelper.Template_Var(scheckbox1,"CheckBox1")
	module_guihelper.Template_return("Button1")
	return
	Template_Hotkeys_Basic_Button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(shotkey1,"Hotkey1")
	module_guihelper.Template_Var(scheckbox1,"CheckBox1")
	module_guihelper.Template_return("Button2")
	return
}
Hotkeys_Advanced(ReturnFunction,GuiInfo:="",AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sbutton1,sbutton2,sedit1
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))
	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		Gui, %guiID%:Add, GroupBox, x12 y10 w140 h110 vsgroupbox1, GroupBox1
		Gui, %guiID%:Add, Edit, x22 y30 w120 h30 vsedit1, Edit
		Gui, %guiID%:Add, Link, x22 y70 w120 h20, Documentation: <a href="http://ahkscript.org/docs/Hotkeys.htm#Symbols">link</a>
		Gui, %guiID%:Add, Link, x22 y90 w90 h20,  Keylist: <a href="http://ahkscript.org/docs/KeyList.htm">link</a>
		Gui, %guiID%:Add, Button, x32 y130 w100 h30 vsbutton1 gTemplate_Hotkeys_Advanced_Button1, Basic
		Gui, %guiID%:Add, Button, x32 y170 w100 h30 vsbutton2 gTemplate_Hotkeys_Advanced_Button2, Done
	}
	module_guihelper.Template_Customize(sedit1,"Edit1")
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1","Hotkey")
	module_guihelper.Template_Customize(sbutton1,"Button1","",1)
	module_guihelper.Template_Customize(sbutton2,"Button2","Done")
	module_guihelper.Template_Show(164,211,"Hotkey")
	return
	Template_Hotkeys_Advanced_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button1")
	return
	Template_Hotkeys_Advanced_Button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_return("Button2")
	return
}

Hotkeys(ReturnFunction,GuiInfo:="",AdditionalVar1:="",AdditionalVar2:=""){
	if(isobject(ReturnFunction))
	{
		AdditionalVar2:=AdditionalVar1,		AdditionalVar1:=GuiInfo,		GuiInfo:=ReturnFunction,		ReturnFunction:=""
		if(GuiInfo.GuiAction == "Button1")
		{
			GuiInfo.Template:=GuiInfo.Template == "Hotkeys_Advanced" ? "Hotkeys_Basic" : "Hotkeys_Advanced"
		}
		if(GuiInfo.GuiAction == "Button2" or GuiInfo.GuiAction == "GuiClose")
		{
			if(GuiInfo.vCheckbox1 == 1)
				GuiInfo.vHotkey1:= "#" GuiInfo.vHotkey1
			GuiInfo.vHotkey1:=GuiInfo.Template == "Hotkeys_Basic" ? GuiInfo.vHotkey1 : GuiInfo.vEdit1
			module_guihelper.template_exec(GuiInfo.ReturnFunction,guiInfo,AdditionalVar1,AdditionalVar2)
			return
		}
		GuiInfo.Hotkey1:=GuiInfo.vHotkey1
		GuiInfo.Edit1:=GuiInfo.vEdit1
	}
	else if(isobject(GuiInfo))
	{
		GuiInfo.ReturnFunction:=ReturnFunction
		GuiInfo.Template:=GuiInfo.Template == "Hotkeys_Advanced" ? "Hotkeys_Advanced" : "Hotkeys_Basic"
		GuiInfo.Checkbox1:="Windows Key"
		GuiInfo.guioptions:=module_guihelper.guioptions
	}
	else
		GuiInfo:={Template: "Hotkeys_Basic",ReturnFunction:ReturnFunction,Checkbox1:"Windows Key",guioptions:module_guihelper.guioptions}
	GuiInfo.Button1:=GuiInfo.Template == "Hotkeys_Basic" ? "Advanced Hotkey" : "Basic Hotkey"
	module_guihelper.Template_Gui_Customize(GuiInfo.guioptions)
	if(GuiInfo.Template == "Hotkeys_Advanced")
		this.Hotkeys_Advanced(A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2)
	else
		this.Hotkeys_Basic(A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2)
}

About(ReturnFunction,GuiInfo:="",AdditionalVar1:="",AdditionalVar2:=""){
	static sgroupbox1,sgroupbox2,sedit1,sbutton1,sbutton2,sbutton3,sdropdownlist1
	if(module_guihelper.template_init(ReturnFunction,A_ThisFunc,GuiInfo,AdditionalVar1,AdditionalVar2))	{
		guiID:=module_guihelper.template_ID(A_ThisFunc)
		Gui, %guiID%:Add, GroupBox, x12 y10 w450 h270 vsgroupbox1 , About Module
		Gui, %guiID%:Add, Edit, x22 y30 w430 h240 vsedit1 ReadOnly, Edit
		Gui, %guiID%:Add, GroupBox, x12 y280 w340 h60 vsgroupbox2, About Extensions
		Gui, %guiID%:Add, DropDownList, x22 y300 w190 h20 R5 vsdropdownlist1, DropDownList
		Gui, %guiID%:Add, Button, x232 y300 w100 h30 vsButton1 gTemplate_About_Button1, About Extension
		Gui, %guiID%:Add, Button, x362 y285 w100 h30 vsbutton2 gTemplate_About_Button2, Updates
		Gui, %guiID%:Add, Button, x362 y320 w100 h30 vsbutton3 gTemplate_About_Button3, Done
	}
	module_guihelper.Template_Customize(sgroupbox1,"GroupBox1","About Module")
	module_guihelper.Template_Customize(sgroupbox2,"GroupBox2","About Extensions")
	module_guihelper.Template_Customize(sbutton1,"Button1","About Extension")
	module_guihelper.Template_Customize(sbutton2,"Button2","Updates")
	module_guihelper.Template_Customize(sbutton3,"Button3","Done")
	module_guihelper.Template_Customize(sedit1,"Edit1","")
	module_guihelper.Template_Customize(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_Show(479,354,"Module Info")
	return
	Template_About_Button1:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button1")
	return
	Template_About_Button2:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button2")
	return
	Template_About_Button3:
	module_guihelper.Template_Submit()
	module_guihelper.Template_Var(sedit1,"Edit1")
	module_guihelper.Template_Var(sdropdownlist1,"DropDownList1")
	module_guihelper.Template_return("Button3")
	return
}
core_file()	{
		return A_LineFile
	}
}