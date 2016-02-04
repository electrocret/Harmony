;Variables replaces variables defined in Action texts with actual variable value
Class module_variablemanager extends module_base_trigger{
	#include *i %A_ScriptDir%\Generated\extension_variablemanager.ahk
	static module_version:= 1.0
	static module_about:="VariableManager Handles the insertion of Variables, and the naming of Variables. It also maintains a registry of Variable Functions`nCreated by Electrocret"
	static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/VariableManager.ahk"
	core_file()	{
		return A_LineFile
	}
	module_init()	{
		this.datastore_Set("Category","module","Core")
		;Registers Name Variables
		Variable_Names:=this.datastore_get("Variable_Names","",Array())
		Loop %  Variable_Names.MaxIndex()
		{
			loopfield:=Variable_Names[A_Index]
			StringgetPos, pos,loopfield,|
			if(ErrorLevel == 0)
			{
				name:=SubStr(loopfield,1,pos)
				pos:=pos+2
				instance:=SubStr(loopfield,pos)
				if(!this.name_reg(name,instance))
					this.name_unreg(name,instance)
			}
		}
		;Registers Variable Functions
		Variable_Functions:=this.datastore_get("Variable_Functions","",Array())
		Loop %  Variable_Functions.MaxIndex()
		{
			if(!this.reg(Variable_Functions[A_Index]))
				this.unreg(Variable_Functions[A_Index])
		}
	}
	name_reg(Name,VarInstance)	{
		if(this.reg(VarInstance))
		{
			StringLower, Name,Name
			this.format_add(name)
			natname:=this.module_format_naturalize(name)
			Names:=this.datastore_get("Names","",Array())
			Variable_Names:=this.datastore_get("Variable_Names","",Array())
			if(Names.contains(Name))
			{
				;Removes Names if already exists
				Variable_Names.removeAt(Variable_Names.indexOf(name "|" this.datastore_get(natname,"Name")))
				this.datastore_set(this.module_format_naturalize(this.datastore_get(natname,"Name"),240),"RName","")
			}
			else
				Names.push(Name)
			if(!Variable_Names.contains(name "|" VarInstance))
				Variable_Names.push(name "|" VarInstance)
			this.datastore_set(natname,"Name",VarInstance)
			this.datastore_set("Names","",Names)
			this.config_set("Variable_Names","",Variable_Names)
			;Sets Reverse Name Lookup Value
			this.datastore_set(this.module_format_naturalize(varinstance,240),"RName",name)
			return 1
		}
		return 0

	}
	name_unreg(Name)	{
		this.format_add(name)
		Names:=this.datastore_get("Names","",Array())
		if(Names.contains(Name))
		{
			StringLower, Name,Name
			;Removes Name from Name list
			Names.removeAt(Names.indexOf(Name))
			this.datastore_set("Names","",Names)
			natname:=this.module_format_naturalize(name)
			;Clears Reverse Name Lookup Value
			this.datastore_set(this.module_format_naturalize(this.datastore_get(natname,"Name"),240),"RName","")
			;Clears Var containing VarInstance
			this.datastore_set(natname,"Name","")
			;Removes Name/VarInstance from config list.
			Variable_Names:=this.datastore_get("Variable_Names","",Array())
			if(Variable_Names.contains(name "|" this.datastore_get(natname,"Name")))
			{
				Variable_Names.removeAt(Variable_Names.indexOf(name "|" this.datastore_get(natname,"Name")))
				this.config_set("Variable_Names","",Variable_Names)
			}
			this.datastore_set(this.module_format_naturalize(varinstance,240),"RName",name)
		}
	}
	reg(VarInstances*)	{
		output:=0
		for index,VarInstance in VarInstances
		{
			if(this.hook(A_thisFunc,VarInstance))
				continue
			if(!isobject(VarInstance))	;Ensures VarInstance is parsed into Var_Func, Var_Info, and Var_Instance
				VarInstance:=this.parseVar(VarInstance)
			;Checks if this is a new Var_Instance
			Variable_Instances:=this.datastore_get("Variable_Instances","",Array())
			if(!Variable_Instances.contains(VarInstance.Var_Instance))
			{
				Variable_Instances.push(VarInstance.Var_Instance)
				this.datastore_set("Variable_Instances","",Variable_Instances)
				Variable_Functions:=this.datastore_get("Variable_Functions","",Array())
				if(this.isVar_Func(VarInstance))
				{
					if(!Variable_Functions.contains(VarInstance.Var_func))
					{
						module_includer.check_includer("module_variablemanager",VarInstance.Var_func)
						Variable_Functions.push(VarInstance.Var_func)
						this.config_set("Variable_Functions","",Variable_Functions)
					}
					Variable_Func_Initialized:=this.datastore_get("Initialized","Variable_Options",Array())
					if(!Variable_Func_Initialized.contains(VarInstance.Var_Func))
					{
						Variable_Func_Initialized.push(VarInstance.Var_Func)
						this.datastore_set("Initialized","Variable_Options",Variable_Func_Initialized)
						;Initializes Variable Function
						options:=this.evaluate(VarInstance,"Initialize")
						;Evaluates Variable's Initialize output for configuration settings
						Variable_Options:=this.datastore_get("Variable_Options","",Array())
						if(isobject(options))
						{
							Loop % options.maxindex()
							{
								optionlist:=this.datastore_get(options[A_Index],"Variable_Options",Array())
								optionlist.push(VarInstance.Var_func)
								this.datastore_set(options[A_Index],"Variable_Options",optionlist)
								if(!Variable_Options.contains(options[A_Index]))
									Variable_Options.push(options[A_Index])
							}
						}
						else
						{
							Loop, Parse, options , |
							{
								optionlist:=this.datastore_get(A_Loopfield,"Variable_Options",Array())
								optionlist.push(VarInstance.Var_func)
								this.datastore_set(A_Loopfield,"Variable_Options",optionlist)
								if(!Variable_Options.contains(A_Loopfield))
									Variable_Options.push(A_Loopfield)
							}
						}
						this.datastore_set("Variable_Options","",Variable_Options)
					}
				}
				else if(Variable_Functions.contains(VarInstance.Var_func))
				{
					this.unreg(VarInstance.Var_func)
					continue
				}
				;Registers this instance of the Variable with Variable Function
				this.evaluate(VarInstance,"Register")
			}
			output:=this.isVar_Func(VarInstance) or output? 1: 0
		}
		return output
	}
	unreg(VariableInstances*)	{
		Variable_Functions:=this.datastore_get("Variable_Functions","",Array())
		for index,VarInstance in VarInstances
		{
			if(!isobject(VarInstance))	;Ensures VarInstance is parsed into Var_Func, Var_Info, and Var_Instance
				VarInstance:=this.parseVar(VarInstance)
			if(!module_dependency.removeDependent("module_variablemanager",VarInstance.Var_Func))
				continue
			if(Variable_Functions.contains(VarInstance.Var_func))
				Variable_Functions.removeAt(Variable_Functions.indexOf(VarInstance.Var_func))
			Variable_Options:=this.datastore_get("Variable_Options","",Array())
			Loop % Variable_Options.MaxIndex()
			{
				optionlist:=this.datastore_get(Variable_Options[A_Index],"Variable_Options",Array())
				if(optionlist.contains(VarInstance.Var_func))
				{
					optionlist.removeAt(optionlist.indexOf(VarInstance.Var_Func))
					this.datastore_set(Variable_Options[A_Index],"Variable_Options",optionlist)
				}
			}
		}
		this.config_set("Variable_Functions","",Variable_Functions)
	}
	format_add(byref instance,force:=0)	{
		if(this.hook(A_thisFunc,instance,force))
			return  this.hook_value(A_thisFunc)
		Stringgetpos, openpos ,instance,[
		if(errorlevel == 1 or openpos != 0 or force)
			instance:="[" instance, errorlevel:=0
		Stringgetpos, closepos ,instance,],R
		if(errorlevel == 1 or closepos != strlen(instance)-1 or force)
			instance:=instance "]"
	}
	format_remove(byref instance, force:=0)	{
		if(this.hook(A_thisFunc,instance,force))
			return  this.hook_value(A_thisFunc)
		Stringgetpos, openpos ,instance,[
		if(openpos == 0 or force)
			stringtrimleft, instance, instance, 1
		Stringgetpos, closepos ,instance,],R
		if(closepos == strlen(instance)-1 or force)
			stringtrimright, instance,instance, 1
	}
	evaluate(Variable, Eventinfo)	{
		if(this.hook(A_thisFunc,Variable,Eventinfo))
			return  this.hook_value(A_thisFunc)
		if(!isobject(Variable))
			Variable:=this.parseVar(Variable)
		if(!isobject(Eventinfo))
		{
			Eventinfo:=this.Module_eventinfo(this.__Class,Eventinfo)
		}
		if(this.isVar_Func(Variable))
		{
			varfunc:=Variable.Var_func
			var_info:=this.module_format_toArray(Variable.Var_Info)
			module_dependency.beginDependentBuild("module_variablemanager",varfunc)
			returnval:=this.module_func_namespace_exec("Variable",varfunc,Var_Info,Eventinfo)
			module_dependency.endDependentBuild()
			return returnval
		}
	}
	parseVar(VariableOrVarInstance)	{
		if(this.hook(A_thisFunc,VariableOrVarInstance))
			return  this.hook_value(A_thisFunc)
		VariableOrVarInstance=%VariableOrVarInstance%
		output:=array()
		this.format_remove(VariableOrVarInstance)
		StringgetPos, pos,VariableOrVarInstance,|
		if(ErrorLevel == 0)
		{
			Var_func:=SubStr(VariableOrVarInstance,1,pos)
			StringLower Var_func, Var_func, T
			output.Var_func:=Var_func
			pos:=pos+2
			output.Var_Info:=this.module_format_toArray(SubStr(VariableOrVarInstance,pos))
		}
		else
		{
			StringLower VariableOrVarInstance, VariableOrVarInstance, T
			output.Var_func:=VariableOrVarInstance
		}
		this.format_add(VariableOrVarInstance)
		output.Var_Instance:=VariableOrVarInstance
		return output
	}
	isVar_Func(VariableOrVarInstance)	{
		if(this.hook(A_thisFunc,VariableOrVarInstance))
			return  this.hook_value(A_thisFunc)
		if(!isobject(VariableOrVarInstance))
			VariableOrVarInstance:=this.parseVar(VariableOrVarInstance)
		return this.module_func_namespace_exists("Variable",VariableOrVarInstance.Var_func)
	}
	name_translate(inputtext,repeattimes:=0)	{
		if(this.hook(A_thisFunc,inputtext,repeattimes))
			return  this.hook_value(A_thisFunc)
		Names:=this.datastore_get("Names","",Array())
		Loop % Names.MaxIndex()
		{
			name:=Names[A_Index]
			listofnames:= listofnames == "" ? name : "," name
			ifinstring, inputtext,	%name%
			{
				replacement:=this.name_getVariableInstance(name)
				StringReplace, inputtext,inputtext, %name%, %replacement%, All
			}
		}
		if inputtext contains %listofnames%
		{
			if(repeattimes > 10)
			{
				this.log_error(A_thisFunc,"Possible Var Name Translate Loop occurring:" inputtext )
				return inputtext
			}
			return this.name_translate(inputtext,repeattimes++)
		}
		return inputtext
	}
	name_getVariableInstance(name)	{
		if(this.hook(A_thisFunc,name))
			return  this.hook_value(A_thisFunc)
		this.format_add(name)
		return this.datastore_get(this.module_format_naturalize(name),"name")
	}
	translate(inputtext, eventinfo)	{
		if(this.hook(A_thisFunc,inputtext,eventinfo))
			return  this.hook_value(A_thisFunc)
		if(!isobject(Eventinfo))
		{
			Eventinfo:=this.Module_eventinfo(this.__Class,Eventinfo)
		}
		inputtext:=this.name_translate(inputtext)
		openskip:=1
		closeskip:=1
		Stringgetpos, openpos,inputtext,[,R			;Checks if there is a VarInstance is in input text
		while !errorlevel
		{
			;Gets possible Var Instance
			closepos:=InStr(inputtext,"]",false,openpos,closeskip)-2
			length:=closepos-openpos
			start:=openpos+2
			varinstance:=Substr(inputtext,start,length)
			varinstance:=this.parseVar(varinstance)
			;Checks if found VarInstance is valid and registers it if it is.
			if(this.reg(varinstance) and eventinfo.directive == "Execute")
			{
				instancetext:= varinstance.Var_Instance , value:=this.datastore_query(varinstance,eventinfo)
				stringreplace, inputtext,inputtext,%instancetext%,%value%,All
			}
			else
			{
				closeskip++
				if(InStr(inputtext,"]",false,openpos,closeskip) == 0)
				{
					closeskip:=1
					openskip++
				}
			}
			Stringgetpos, openpos,inputtext,[,R%openskip%			;Checks if there is another VarInstance is in input text
		}
		return inputtext
	}
	datastore_query(varinstance,eventinfo)	{
		if(this.hook(A_thisFunc,varinstance))
			return  this.hook_value(A_thisFunc)
		if(!isobject(varinstance))
			varinstance:=this.parseVar(varinstance)
		cachetest:=this.datastore_get(this.module_format_naturalize(varinstance.Var_Instance,240),"VCache")
		if(cachetest != "")		{
			return cachetest
		}
		eventinfo.directive:="Translate"
		output:=this.evaluate(varinstance,eventinfo)
		eventinfo.directive:="Execute"
		return output
	}
	cache(VariableFunc,Var_Info,Value)	{
		if(isfunc(VariableFunc))
		{
			StringgetPos, testpos,VariableFunc,Variable_
			if(testpos == 0 && Errorlevel == 0)
			{
				;Basic Variable Function
				Stringtrimleft, VariableFunc, VariableFunc, 9
			}
			else if(errorlevel)
			{
				;Basic Module variable
				Stringtrimright, VariableFunc, VariableFunc, 9
				VariableFunc:=module_manager.Core_format_module_Readable(VariableFunc)
			}
			else
			{
				;Module SubVariable
				StringgetPos, modpos,VariableFunc,.
				testpos:=testpos+2
				VariableFunc:=module_manager.Core_format_module_Readable(SubStr(VariableFunc,1,modpos)) "." SubStr(VariableFunc,testpos)
			}
			StringLower VariableFunc, VariableFunc, T
		}
		nat_varinstance:=this.module_format_naturalize("[" VariableFunc "|" this.module_format_toString(Var_Info) "]",240)
		name:=this.datastore_get(nat_varinstance,"RName")
		if(this.hook(A_thisFunc,VariableFunc,Var_Info,Value,nat_varinstance,name))
			return  this.hook_value(A_thisFunc)
		this.datastore_set(nat_varinstance,"VCache",Value)
		if(name != "")
			this.trigger_fire(Value,name)
	}
	wizard(returnfunction, additionalvar1:="", additionalvar2:="", wiztype:="NameWizard")	{
		if(this.hook(A_thisFunc,returnfunction,additionalvar1,additionalvar2,wiztype))
			return  this.hook_value(A_thisFunc)
		static ginfocache
		if(isobject(ginfocache))
		{
			ginfocache.Var_Info:=returnfunction
			VarInstanceString:=this.module_format_toString(returnfunction)
			ginfocache.Var_Instance:="[" ginfocache.Var_func "|" VarInstanceString "]"
			ginfo:=ginfocache
			ginfocache:=""
			module_guihelper.template_exec(ginfo.returnfunction,ginfo,ginfo.additionalvar1,ginfo.additionalvar2)
			return
		}
		if(isobject(returnfunction))
		{
			wiztype:=returnfunction.wiztype
			returnfunction.template:="VariableWizard"
			if(returnfunction.GuiAction == "GuiClose")
			{
				module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.additionalvar1,returnfunction.additionalvar2)
				return
			}
			else if( returnfunction.GuiAction == "Button2")
			{
				returnfunction.wiztype:= returnfunction.wiztype == "NameWizard" ? "VariableWizard" : "NameWizard"
				wiztype:=returnfunction.wiztype
			}
			else if( returnfunction.GuiAction == "Button1" and returnfunction.vDropDownlist1 != "")
			{
				if wiztype in VariableWizard,VariableWizardOnly
				{
					returnfunction.Var_func:=returnfunction.vDropDownlist1
					ginfocache:=returnfunction
					possibleVarInfo:=this.evaluate(ginfocache,"Wizard")
					;Checks if Variable's Wizard directly returned a value.
					if(possibleVarInfo != "" or isobject(possibleVarInfo))
					{
						this.wizard(possibleVarInfo)
					}
					return
				}
				else if wiztype in NameWizard,NameWizardOnly
				{
					returnfunction.Var_Instance:=returnfunction.vDropDownlist1
					module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.additionalvar1,returnfunction.additionalvar2)
				}
			}
		}
		else
		{
			ginfo:={returnfunction: returnfunction, Additionalvar1: additionalvar1, Additionalvar2: additionalvar2,Button1: "Select",wiztype: wiztype,Windowtitle: "Variable Wizard"}
			returnfunction:=ginfo
		}
		if wiztype in VariableWizard,VariableWizardOnly
		{
			wizvars:=this.datastore_Get("wizard","Variable_Options",Array())
			Loop % wizvars.MaxIndex()
			{
				varlist.="|" wizvars[A_Index]
			}
			returnfunction.Button2:="Existing Variable"
			returnfunction.Groupbox1:= "Variable Type"
			returnfunction.DropDownList1:= varlist == "" ? "|" : varlist
			if(wiztype == "VariableWizardOnly")
				module_guitemplate.OneButtonDropdown(A_thisFunc,returnfunction)
				else
				module_guitemplate.TwoButtonDropdown(A_thisFunc,returnfunction)
		}
		else
		{
			namevars:=this.datastore_Get("Names","",Array())
			Loop % namevars.MaxIndex()
			{
				varlist.="|" namevars[A_Index]
			}

			returnfunction.Button2:="Custom Variable"
			returnfunction.Groupbox1:= "Select Variable"
			returnfunction.DropDownList1:= varlist == "" ? "|" : varlist
			if(wiztype == "NameWizardOnly")
				module_guitemplate.OneButtonDropdown(A_thisFunc,returnfunction)
				else
				module_guitemplate.TwoButtonDropdown(A_thisFunc,returnfunction)
		}
	}
	Editor(returnfunction, Variable:="",additionalvar1:="",additionalvar2:="")	{
		if(this.hook(A_thisFunc,returnfunction,variable,additionalvar1,additionalvar2))
			return  this.hook_value(A_thisFunc)
		if(isobject(returnfunction))
		{
			if(returnfunction.Template == "editor")
			{
				;Handles Editor Menu
				varinst:=returnfunction.vEdit1
				varinst=%varinst%
				;Checks if extra brackets are surrounding the varinstance
				this.format_add(varinst,1)
				returnfunction.template:="VariableEditor"
				returnfunction.Var_Instance:=varinst
				if(returnfunction.GuiAction == "Button1")
				{
					;Done Button
					module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.AdditionalVar1,returnfunction.AdditionalVar2)
					return
				}
				if(returnfunction.GuiAction == "Button2")
				{
					;Opens Variable Wizard
					this.wizard(A_thisfunc,returnfunction,"","VariableWizard")
					return
				}
				;Undefined Gui Action
				returnfunction.Var_Instance:=returnfunction.OriginalVariable_Instance 
				module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.AdditionalVar1,returnfunction.AdditionalVar2)
				return
			}
			else if(returnfunction.GuiAction == "Button1" and Variable.GuiAction == "Button2")
			{	
				;Handles Variable Wizard
				msgbox, 4,Variable Editor,Do you want to replace the existing Variable? `n(it will otherwise be put on your clipboard fully formatted)
				ifmsgbox, Yes
				{
					newtext:=Variable.Var_Instance
					this.format_remove(newtext)
					Variable.Edit1:=newtext
				}
				else
				{
					varinstance:=Variable.Var_Instance
					module_guihelper.Clipboard_set(varinstance)
					TrayTip, Variable Wizard, Variable set to Clipboard`n %varinstance%, 5
				}
			}
			module_guitemplate.editor(A_thisfunc,Variable)
			return
		}
		this.format_remove(Variable,1)
		;Creates Initial GuiInfo
		ginfo:={groupbox1: "Edit Variable", Button1: "Done",Button2: "Variable Wizard", Button3_hide: 1, Button4_hide: 1, Edit1: Variable, OriginalVariable_Instance: Variable, Windowtitle: "Variable Editor",returnfunction: returnfunction,AdditionalVar1:additionalvar1, AdditionalVar2:AdditionalVar2}
		module_guitemplate.editor(A_thisfunc,ginfo)
	}
	action(Action_Info,Eventinfo)	{
		if(this.hook(A_thisFunc,Action_Info,Eventinfo))
			return  this.hook_value(A_thisFunc)
		if( eventinfo.directive == Execute)
		{
			return this.evaluate(Action_Info,Eventinfo)
		}
	}
	module_configure(guiinfo:="",secondaryguiInfo:=""){
		if(this.hook(A_thisFunc,guiinfo,secondaryguiInfo))
			return  this.hook_value(A_thisFunc)
		if(isobject(guiinfo))
		{
			if(Guiinfo.Template == "manager")
			{
				;Edit Existing selected Variable Button
				if(GuiInfo.GuiAction == "Button2" and guiInfo.vListbox1 != "")
				{
					additionalguiinfo:={Button3_hide: 0, Button3: "Delete Variable"}
					module_guihelper.Template_Gui_Customize(additionalguiinfo)
					this.editor(A_thisFunc, this.name_getVariableInstance(guiInfo.vListbox1) ,guiInfo)
					return
				}
				if(GuiInfo.GuiAction == "Button3")
				{	
					InputBox, newVar , New Variable, New Variable Function Name:
					if(!ErrorLevel)
					this.reg(newVar)
				}
				
				;Create New Variable Button
				if(GuiInfo.GuiAction == "Button1")
				{
					InputBox, newvarName , New Variable Name, Please enter the name for the new variable:
					if(errorlevel == 0)
					{
						guiInfo.vListbox1:=newvarName
						MsgBox, 4, , Do you want to use the Variable Wizard?
						IfMsgBox, Yes
							this.wizard(A_thisfunc,GuiInfo,"","VariableWizardOnly")
						else IfMsgBox, No
						{
							additionalguiinfo:={Button3_hide: 0, Button3: "Delete Variable"}
							module_guihelper.Template_Gui_Customize(additionalguiinfo)
							this.editor(A_thisFunc,"",GuiInfo)
						}
					}
				}
				;Finished with Variable Manager
				if(GuiInfo.GuiAction == "Button4" or GuiInfo.GuiAction == "GuiClose")
				{
					module_manager.module_configure()
					return
				}
			}
			else if(GuiInfo.Template == "VariableEditor")
			{
				if(GuiInfo.GuiAction == "Button3")
				{
					selected:=secondaryguiInfo.vListbox1
					MsgBox, 4, , Are you sure you would like to Delete %selected%?
					IfMsgBox, Yes
						this.name_unreg(selected)
				
				}
				if(GuiInfo.GuiAction == "Button1" or GuiInfo.GuiAction == "GuiClose")
				{
					this.name_reg(secondaryguiInfo.vListbox1,GuiInfo.Var_Instance)
				}
			}else if(GuiInfo.template == "VariableWizard")
			{
				additionalguiinfo:={Button3_hide: 0, Button3: "Delete Variable"}
				module_guihelper.Template_Gui_Customize(additionalguiinfo)
				this.editor(A_thisFunc,GuiInfo.Var_Instance,secondaryguiInfo)
				return
			}
		}
		Names:=this.datastore_get("Names","",Array())
		Loop % RegisteredNames.MaxIndex()
			varnamelist.="|" Names[A_Index] 

		ginfo:={groupbox1: "Variables",Button1: "Add Variable",Button2: "Edit Variable", Button3: "Add Variable Function",Button4: "Done", Listbox1: varnamelist ,Windowtitle: "Variable Manager"}
		module_guitemplate.manager(A_thisFunc,ginfo)
	}
	module_dependency(Directive,DependentName)	{
		if(Directive == "remove")
			return this.unreg(DependentName)
		else if(Directive == "add")
			return this.reg(DependentName)
	}
	trigger_reg(variable_name, Action, trigpriority:=0)	{
		this.format_add(variable_name)
		return base.trigger_reg(variable_name,Action,trigpriority)
	}
	trigger_unreg(variable_name, Action, trigpriority:="")	{
		this.format_add(variable_name)
		return base.trigger_unreg(variable_name,Action,trigpriority)
	}
}	

/*
Variable_Example(Var_Info, Eventinfo)

Directive: Initialize -initialize function when first registered|Reg - ran when there is a new instance|Update - Ran when a Trigger fires a Variable Update |Translate - Ran when a value for the instance is wanted.
Instance: This is the unique variable instance info, or is the Trigger_Type when an update is done.

*/