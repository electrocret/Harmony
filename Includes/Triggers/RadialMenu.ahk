Include_Trigger_RadialMenu(){
	module_manager.reg("module_radialmenu")
}
Class module_radialmenu extends module_base{
	static module_version:=1.0
	static module_about:=""
	static module_updateurl:="https://drive.google.com/file/d/0B3ArE2gxQ2P-U3poSTNiQ0lTbDg/view?usp=sharing"
	static ConfigVariables:=Array("defaultselectmethod","skin")
	static skin:="Anectra's target"
	static defaultselectmethod:="r"
	static defaultxpos:=""
	static defaultypos:=""
	static menus:=""
		static module_datastore_default:="file"
	#include *i %A_ScriptDir%\Generated\Extension_RadialMenu.ahk
	module_preinit()
	{
		module_dependency.extension(this.__Class,"rm2")
	}
	module_init()
	{
		this.datastore_set_Default_Datastore("this")
		module_actionmanager.reg("RadialMenu")
		rmdir:=module_manager.datastore_get("Include_Resources","Core_Directory") "\Radialmenu"
		this.RM2_On( rmdir "\Skins\" this.skin)
		;Reads menu files
		Loop, Files, %rmdir%\menus\*.txt
		{
			StringTrimRight, menuname, A_LoopFileName, 4
			StringLower, menuname,menuname
			this.menus.="|" menuname
			natmenuname:=this.module_format_naturalize(menuname)
			this["menu_" natmenuname] := new module_radialmenu.RM2Menu(A_LoopFileFullPath,menuname)
		}
		this.RM2_Off()
	}
	show(menuname, options:="")
	{
		natmenuname:=this.module_format_naturalize(menuname)
		if(isobject(this["menu_" natmenuname]))
		{
			selectmethod:=this.defaultselectmethod,xpos:=this.defaultxpos,ypos:=this.defaultypos
			if(isobject(options))
			{
				selectmethod:=options.selectmethod == ""? selectmethod: options.selectmethod
				xpos:=options.x is number ? options.x : xpos
				ypos:=options.y is number ? options.y : ypos
			}

			this["menu_" natmenuname].show(selectmethod,"","",xpos,ypos)
		}
	}
	action(Action_Info,eventinfo)
	{
		directive:=eventinfo.directive
		if(directive == "Execute")
		{
			if(isobject(Action_Info))
				this.show(Action_Info.menu, Action_Info)
			else
				this.show(Action_Info)

		}
		if(directive == "Wizard")
		{
			if(isobject(Action_Info))
			{
				module_actionmanager.Wizard(Action_Info.vDropdownlist1)
				return
			}
			ginfo:={Button1: "Select", Groupbox1: "Radial Menus", DropdownList1: this.menus}
			module_guitemplate.OneButtonDropdown(A_thisfunc,ginfo,EventInfo)
		}
		if(directive == "Initialize")
		{
			module_manager.module_reg(this.__Class)
			return "Wizard"
		}
	}
	Class RM2Menu {		; by Learning one - Minor edits by Electrocret For compatibility with Harmony.
	/*
	Class RM2Menu is not built-in RM2module code because it is incompatible with AutoHotkey Basic.
	But as AutoHotkey_L is official AutoHotkey now, it's recommended to make menus by using this class because it's much more practical than "RM2_CreateMenu()" style.
	*/

	static FuncParamDelimiter := "|", MenusDisplayedInClickToSelectMode := [], EnableHotkeys := 1

	__New(Constructor, Name, IconsFolder="", MaxAllowedItems=60, EqualSign = "=") {	; Creates radial menu object
		this.natname:=module_radialmenu.module_format_naturalize(name)
		this.Name := Name	
		
		Att := FileExist(Constructor)
		if (Att != "" and InStr(Att, "D") = 0)
			FileRead, ConstructorVariable, %Constructor%
		else
			ConstructorVariable := Constructor
		
		IsSectionValid := 0, TotalItems := 0
		Loop, parse, ConstructorVariable, `n
		{
			Field := Trim(A_LoopField, " `t`r")
			if Field is space						; blank
			Continue
			
			if (SubStr(Field, 1, 1) = ";")			; comment
			Continue
			
			if (SubStr(Field, 1, 1) = "[") {			; Section
				IsSectionValid := 0
				Field := SubStr(Field, 2, StrLen(Field)-2)	; trims first and last characters - []
				if (Field = "")
					continue
				
				if (SubStr(Field,1,4) = "Item") {
					StringTrimLeft, ItemNum, Field, 4
					if (ItemNum > MaxAllowedItems)	; example - ignore Item1000
						continue
					else
						TotalItems += 1
				}
				
				IsSectionValid := 1
				CurSection := Field		; example: Item1
				
				if (CurSection != LastCurSection and IsSectionValid = 1) {	; create sub-object
					LastCurSection := CurSection
					this.Insert(CurSection, Object())
				}
				Continue
			}
			if (IsSectionValid = 0)
				continue
			
			EqualPos := InStr(Field, EqualSign)		; get Equal sign position
			if (EqualPos = 0)						; not found
				Continue
			
			var := SubStr(Field, 1, EqualPos-1)		; set&clear variable name (key)
			StringReplace, var, var, %A_Space%, ,all
			StringReplace, var, var, %A_Tab%, ,all
			if var is space
				Continue
			
			val := SubStr(Field, EqualPos+1)		; set&clear value
			val := Trim(val, " `t")
			if (var != "Action") {
				StringReplace, val, val, |, %A_Space%, All		; forbidden character
				StringReplace, val, val, >, %A_Space%, All		; forbidden character
			}
			else
				module_actionmanager.reg(val)
			if val is space
				val := ""
			Transform, val, Deref, %val%
				if !(val = "")
			this[CurSection].Insert(Var, Val)	; var(key) = val
		}
		For k,v in this	; check item existance, refine icon
		{
			if (SubStr(k,1,4) = "Item") {
				Icon := this[k]["Icon"]
				if (Icon != "") {		; refine icon
					if (FileExist(Icon) != "")
						RefIcon := Icon
					else if (FileExist(IconsFolder "\" Icon) != "")
						RefIcon := IconsFolder "\" Icon
					else if (FileExist(IconsFolder "\" Icon ".png") != "")
						RefIcon := IconsFolder "\" Icon ".png"
					else
						RefIcon := ""
					
					if (Instr(FileExist(RefIcon), "D") > 0)
						RefIcon := ""
					
					this[k]["Icon"] := RefIcon
				}
				
				if (this[k]["Text"] = "" and this[k]["Icon"] = "")		; item must have text or icon to exist!
					ToRemoveKeysList .= k "|"
			}
		}
		
		ToRemoveKeysList := RTrim(ToRemoveKeysList, "|")
		if (ToRemoveKeysList != "") {
			Loop, parse, ToRemoveKeysList, |
				this.Remove(A_LoopField), TotalItems -= 1
		}

		if (TotalItems < 1)		;  menu doesn't have any item defined!
			return
		
		this.CreateMenu()
	}
	
	Show(SelectMethod="", key="", options="",ShowPosX="", ShowPosY="") {	; Shows radial menu and if item is selected, it executes item action. Returns SelectedItemNumber.
		/*
		For parameters see RM2_Handler() documentation in RM2module.
		
		SelectedItemNumber value can be:
		- 0 if user selected center of menu - this can be used to close displayed submenu
		- <number greater than 0> if user selected item (example: 1, 7, 23, etc.)
		- <blank> in all other cases - when nothing is selected
		*/
		if options not contains pos
			options .= " pos"		; "pos"	returns item's position instead of its refined text
		if options not contains iicr
			options .= " iicr.0"	; "is in circle return" - returns specified value (0 in this case) if user selected "close menu circle" (center of menu).
		
		if (SelectMethod = "c")		; click to select
			module_radialmenu.RM2Menu.MenusDisplayedInClickToSelectMode.Insert(this.natname)		; says that this menu is corrently displayed in ClickToSelectMode - will temporarly block LButton
		SelectedItemNumber := module_radialmenu.RM2_Handler(this.natname, SelectMethod, key, options, ShowPosX, ShowPosY)
		if (SelectMethod = "c") {		; click to select - remove from list to unblock LButton
			For k,v in module_radialmenu.RM2Menu.MenusDisplayedInClickToSelectMode
			{
				if (v = this.natname) {
					ToRemoveNum := k
					break
				}
			}
			module_radialmenu.RM2Menu.MenusDisplayedInClickToSelectMode.Remove(ToRemoveNum)
		}
		
		if (SelectedItemNumber > 0)	; User selected item - execute item action (if any)
			this.Execute(SelectedItemNumber)
		return SelectedItemNumber
	}

	Execute(ItemNumber) {	; executes item action; 1) function (fun prefix) or 2) subroutine (sub prefix) or 3) calls Run command
		ItemAction := this["Item" ItemNumber].Action
		if (ItemAction = "")
			return
		EventInfo:=module_radialmenu.Module_eventinfo(this.Name " " ItemNumber, "Execute", ItemNumber)
		module_actionmanager.execute(ItemAction,Eventinfo)
	}
	
	CreateMenu() {	; creates radial menu GUI
		GuiNum := this.natname
		TotalItems := 0
		For k,v in this
		{
			if (SubStr(k,1,4) = "Item") {
				StringTrimLeft, ItemNum, k, 4
				if (ItemNum > TotalItems)
					TotalItems := ItemNum
			}
		}
		Loop % TotalItems
		{
			CurItem := this["Item" A_Index].Text ">" this["Item" A_Index].Icon ">" this["Item" A_Index].Tooltip ">" this["Item" A_Index].Submenu ">" this["Item" A_Index].SpecItemBack ">" this["Item" A_Index].SpecItemFore
			
			CurItem := RTrim(CurItem, ">")
			ItemAttributes .= CurItem "|"
			CurItem := ""
		}
		ItemAttributes := RTrim(ItemAttributes, "|")
		SpecMenuBack := this.General.SpecMenuBack, SpecMenuFore := this.General.SpecMenuFore, OneRingerAtt := this.General.OneRingerAtt
		CentralTextOrImageAtt := this.General.CentralText ">" this.General.CentralImage ">" this.General.CentralImageSizeFactor
		CentralTextOrImageAtt := RTrim(CentralTextOrImageAtt, ">")
		module_radialmenu.RM2_CreateMenu(GuiNum,ItemAttributes,SpecMenuBack,SpecMenuFore,OneRingerAtt,CentralTextOrImageAtt)
	}
	
	HotkeysConditions(Context) {
		if (module_radialmenu.RM2Menu.EnableHotkeys != 1)	; class hotkeys are disabled
			return
			
		if (Context="ClickToSelect") {
			if (module_radialmenu.RM2Menu.MenusDisplayedInClickToSelectMode.MaxIndex() != "") {	; there is/are menu displayed in ClickToSelect mode
				MouseGetPos,,, hWinUnderMouse
				
				hWinItemGlow := module_radialmenu.RM2_Reg("ItemGlowHWND")	; item glow
				if (hWinUnderMouse = hWinItemGlow)
					return 1
				
				For k,v in module_radialmenu.RM2Menu.MenusDisplayedInClickToSelectMode
				{
					hWinThisRadialMenu := module_radialmenu.RM2_Reg("M" v "#HWND")		; menu			
					if (hWinUnderMouse = hWinThisRadialMenu)
						return 1
				}
			}
		}
	}
}

	module_configure(Guiinfo:="",SecondaryGuiInfo:="")
	{
		if(isobject(GuiInfo))
		{
			if(GuiInfo.Template == "TwoButtonDropdown")
			{
				if(GuiInfo.GuiAction == "Button2")
				{
					rmdir:=module_manager.datastore_get("Include_Resources","Core_Directory") "\Radialmenu"
					if(GuiInfo.vDropdownlist1 == "Skin")
					{
						MsgBox , 0, Radial Menu, NOTE: The script will need to Reload after a skin change has been made..
						Loop, %rmdir%\Skins\*,2
						{
							if A_LoopFileName not contains +
								SkinsList .= "|" A_LoopFileName
						}
						ginfo:={Button1: "Select",Groupbox1:"Skin",DropdownList1:SkinsList,DropdownList1_Choose: this.skin}
						module_guitemplate.OneButtonDropdown(A_thisfunc,Ginfo,GuiInfo)
						return
					}
					else if(GuiInfo.vDropdownlist1 == "SelectMethod")
					{
						ginfo:={Button1: "Select",Groupbox1:"SelectMethod",DropdownList1:"|ReleaseToSelect|ClickToSelect"}
						module_guitemplate.OneButtonDropdown(A_thisfunc,Ginfo,GuiInfo)
						return
					}
					else if(GuiInfo.vDropdownlist1 == "Menus")
					{
						MsgBox , 0, Radial Menu Editor, NOTE: Any changes to menus in Radial Menu Editor will not be seen until the script Reloads.
						module_manager.Core_configmode("reload")
						Run,  %rmdir%\RMD.ahk, %rmdir%\menus
						return
					}
				}
				else
				{
					module_manager.module_configure()
					return
				}
			}
			if(GuiInfo.Template == "OneButtonDropdown")
			{
				if(GuiInfo.GuiAction == "Button1" and GuiInfo.vDropdownlist1 != "")
				{
					if(SecondaryGuiInfo.vDropdownlist1 == "SelectMethod")
						this.config_set("defaultselectmethod","",substr(GuiInfo.vDropdownlist1,1,1))
					if(SecondaryGuiInfo.vDropdownlist1 == "Skin")
						this.config_set("skin","",GuiInfo.vDropdownlist1,1,1)
				}
			}
		}
		ginfo:={Button1: "Done", Button2: "Edit",Groupbox1: "Settings",DropdownList1:"|Skin|SelectMethod|Menus"}
		module_guitemplate.TwoButtonDropdown(A_thisfunc,ginfo)
	
	}
}
