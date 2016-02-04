Class module_funchelper extends module_base{
	static module_version:= 1.0
	static module_about:="FuncHelper helps simple functions that do not need to become full modules, but would like to have some basic configurations or pull on outside resources. `n Created by Electrocret"
	static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/FuncHelper.ahk"
	#include *i %A_ScriptDir%\Generated\Extension_funchelper.ahk
	module_init()	{
		this.datastore_Set("Category","module","Core")
	}
	config_set(FunctionName,Variable,namespace:="",Value:="",datastore:="")	{
		this.config_track_funcs(FunctionName,Namespace,Variable)
		return base.config_set(Variable,namespace,value,datastore)
	}
	config_add(FunctionName,Variable,namespace:="",DefaultValue:="",datastore:="")	{
		this.config_track_funcs(FunctionName,Namespace,Variable)
		if(!this.config_isVal(Variable,Namespace))
			this.config_set(FunctionName,Variable,Namespace,DefaultValue,datastore)
		return this.datastore_Get(Variable,Namespace,DefaultValue,datastore)
	}
	config_clear_unused(noprompt:=0)	{
		if(this.hook(A_thisFunc,noprompt))
			return  this.hook_value(A_thisFunc)
		namespaces:=this.config_namespaces()
		loop % namespaces.maxIndex()
		{
			variables:=this.config_ConfigVariables(namespaces[A_Index])
			loop % variables.maxIndex()
			{
				if(this.datastore_Get(variables[A_Index] "_funcs",namespaces[A_Index],Array()) == "")
					unused.="`n" namespaces[A_Index] ">" variables[A_Index]
			}
		}
		if(unused == "")
		{
			if(!noprompt)
				msgbox,,Cleanup Config, No Unused Configurations found.
			return
		}
		if(!noprompt)
		{
			MsgBox, 4, Cleanup Config ,Do you want to cleanup the following unused Configurations? `n %unused%
			ifmsgbox, no
				return
		}
		loop, Parse, unused, `n
		{
			StringgetPos, pos,A_loopfield,>
			if(ErrorLevel == 0)
			{
				namespace:=SubStr(A_loopfield,1,pos)
				pos:=pos+2
				Variable:=SubStr(A_loopfield,pos)
				this.config_remove(variable,namespace)
			}
		}
	}
	;Tracks functions that uses a config value
	config_track_funcs(FunctionName,namespace,Variable)	{
		if(this.hook(A_thisFunc,FunctionName,namespace,Variable))
			return  this.hook_value(A_thisFunc)
		funcsusedin:=this.datastore_Get(Variable "_funcs",namespace,Array())
		if(!funcsusedin.contains(FunctionName))
		{
			funcsusedin.push(FunctionName)
			this.datastore_Set(Variable "_funcs",namespace,funcsusedin)
		}
	}
	config_Info(namespace, Variable, display:=1)	{
		if(this.hook(A_thisFunc,namespace,Variable,display))
			return  this.hook_value(A_thisFunc)
		funcsusedin:=this.datastore_Get(Variable "_funcs",namespace,Array())
		loop % funcsusedin.maxIndex()
		{
			funclist.=", " funcsusedin[A_Index]
			description:=this.datastore_get(funcsusedin[A_Index] "_description",namespace "_" Variable,"","file")
			if(description !="")
			{
				descriptions.="`n   "funcsusedin[A_Index] " - " description "`n"
			}
		}
		if(descriptions != "")
		{
			descriptions:="`nFunction Usage Descriptions:" descriptions
		}
		StringTrimleft, funclist,funclist,1
		output:="namespace: " namespace "`nVariable: " Variable "`nFunctions used by: " funclist descriptions
		if(display)
			msgbox, 0, %namespace% - %Variable% Info, %output%
		return output
	}
	config_description(FunctionName,namespace,Variable,Description_of_how_func_uses_Value)	{
		if(this.hook(A_thisFunc,FunctionName,namespace,Variable,Description_of_how_func_uses_Value))
			return  this.hook_value(A_thisFunc)
		this.config_track_funcs(FunctionName,namespace,Variable)
		this.datastore_set(FunctionName "_description",namespace "_" Variable,Description_of_how_func_uses_Value,"file")
	}
	config_edit_dropdown(namespace,Variable,Choices)	{
		if(this.hook(A_thisFunc,namespace,Variable,Choices))
			return  this.hook_value(A_thisFunc)
		this.datastore_set("ConfigGui", namespace "_" Variable, "dropdown","file")
		this.datastore_set("ConfigOptions",namespace "_" Variable,Choices,"file")
	}
	config_edit_inputbox(namespace, Variable, Additionaltext:=""){
		if(this.hook(A_thisFunc,namespace,Variable,Additionaltext))
			return  this.hook_value(A_thisFunc)
		this.datastore_set("ConfigGui", namespace "_" Variable, "inputbox","file")
		this.datastore_set("ConfigOptions",namespace "_" Variable,Additionaltext,"file")
	}
	module_configure(guiinfo:="",secondaryGui:=""){
		if(this.hook(A_thisFunc,guiinfo,secondaryGui))
			return  this.hook_value(A_thisFunc)
		if(isobject(guiinfo))
		{
			if(guiinfo.Template == "OneButtonDropdown")
			{
				dropdowngui:=guiinfo
				secondaryGui:=guiinfo.threebuttondropdown
				guiInfo:=guiinfo.manager
				if(dropdowngui.guiaction == "Button1")
				{
					Variable:=guiInfo.vListbox1
					StringgetPos, pos,Variable,:
					Variable:=SubStr(Variable,1,pos)
					namespace:=secondaryGui.vDropdownlist1
					newvalue:=dropdowngui.vDropdownlist1
					base.config_set(Variable,namespace,newvalue)
				}
			}
			else if(guiinfo.Template == "ThreeButtonDropdown")
			{
				if(guiinfo.guiaction == "Button1")
				{
					this.config_clear_unused()
				}
				else if(guiinfo.guiaction == "Button2" and guiInfo.vDropdownlist1 != "")
				{
					secondaryGui:=guiinfo
					guiinfo:=""
				}
				else	if(guiinfo.guiaction == "Button3" or guiinfo.guiaction == "GuiClose")
				{
					module_manager.module_configure()
					return
				}
			}
			else if(guiInfo.Template == "manager")
			{
				namespace:=secondaryGui.vDropdownlist1
				if(guiInfo.vListbox1 != "")
				{
					Variable:=guiInfo.vListbox1
					StringgetPos, pos,Variable,:
					Variable:=SubStr(Variable,1,pos)
					if(guiinfo.guiaction == "Button1" )
					{
						;Edit Variable Value
						currentvalue:=module_funchelper.datastore_Get(Variable,namespace)
						gtype:=module_funchelper.filedatastore_get("ConfigGui", namespace "_" Variable)
						options:=module_funchelper.filedatastore_get("ConfigOptions", namespace "_" Variable)
						if(gtype == "dropdown")
						{
							;Dropdownlist
							ginfo:={Dropdownlist1: options, Dropdownlist1_ChooseString: currentvalue, Groupbox1: Variable " Value:", Button1: "Select",manager: guiInfo, threebuttondropdown: secondaryGui, Windowtitle: "Edit " variable}
							module_guitemplate.OneButtonDropdown(A_thisFunc, ginfo)
							return
						}
						else
						{
							;InputBox
							InputBox, newvalue , Edit %Variable%, Set %Variable% to: `n %options%, , , , , , , , %currentvalue%
							if(!ErrorLevel)
							{
								base.config_set(Variable,namespace,newvalue)
							}
							else
								ErrorLevel:=0
						}
					}
					if(guiinfo.guiaction == "Button2" )
					{
						MsgBox, 4, Delete Variable , Are you sure you would like to Delete %variable%?
						IfMsgBox, Yes
						{
							this.config_remove(variable,namespace)
						}
					}
					if(guiinfo.guiaction == "Button3" )
					{
						this.config_Info(namespace, Variable)
					}
				}
				if(guiinfo.guiaction == "Button4" or guiinfo.guiaction == "GuiClose")
				{
					guiinfo:=secondaryGui
					secondarygui:=""
				}
			}
		}
		if(isobject(secondaryGui))
		{
			namespace:=secondaryGui.vDropdownlist1
			vars:=this.config_ConfigVariables(namespace)
			Loop % vars.maxIndex()
			{
				value:=this.module_format_toString(this.datastore_Get(vars[A_Index],namespace))
				Stringreplace, value,value, |, `,,All
				varlist.="|" vars[A_Index] ": " value
			}
			ginfo:={groupbox1: "Variables in" namespace ,Button1: "Edit Variable",Button2: "Delete Variable", Button3: "Variable Info",Button4: "Done", Listbox1: varlist ,Windowtitle: "Manager for Config Group: " namespace}
			module_guitemplate.manager(A_thisFunc,ginfo,secondaryGui)
			return
		}
		namespaces:=this.config_namespaces()
		Loop % Namespaces.maxIndex()
		{
			confgrouplist.="|" Namespaces[A_Index]
		}
		GInfo:={Windowtitle: "Configure Functions", groupbox1: "Config Groups", Button1: "Cleanup Unused Configs",Button2: "Edit Config Group",Button3: "Done",Dropdownlist1: confgrouplist}
		module_guitemplate.ThreeButtonDropdown(A_thisFunc,GInfo)
	}
	core_file()
	{
		return A_LineFile
	}
}