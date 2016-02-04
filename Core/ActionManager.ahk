Action_Test(action_info,eventinfo){
	event_name:=eventinfo.event_name,	event_module:=eventinfo.event_module.__Class,	event_data:=eventinfo.event_data, directive:=eventinfo.directive
	if(directive == "Initialize")
	{
		Return
	}
	msgbox 0,Test,Action Info:%action_info%`nEvent Name:%event_name%`nEvent Module:%event_module%`nEvent Data:%event_data%`nDirective:%directive%
}
Action_None(action_info,eventinfo){
}
;Actions processes Action text and executes related actions
Class module_actionmanager extends module_base{
	#include *i %A_ScriptDir%\Generated\Extension_actionmanager.ahk
	static module_version:= 1.0
	static module_about:="ActionManager Handles the execution of Actions and maintains a registry of Action Functions."
	static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/ActionManager.ahk"
	module_init()	{
		this.datastore_Set("Category","module","Core")
		Action_Functions:=this.datastore_get("Action_Functions","",Array("Test","None"))
		Loop % Action_Functions.maxindex()
			this.reg(Action_Functions[A_Index])
	}
	reg(Actions*)	{
		output:=0
		for index,Action in Actions
		{
			if(this.hook(A_thisFunc,action))
				continue
			if(!isobject(Action))
			{
				Action:=this.parseAction(Action,0)
			}
			if(Action.Action_Func == "" and Action.Action_Instance == "")
				continue
			Action_Function_Instances:=this.datastore_get("Action_Function_Instances","",Array())
			if(!Action_Function_Instances.contains(Action.Action_Instance))
			{
				Action_Function_Instances.push(Action.Action_Instance)
				this.datastore_set("Action_Function_Instances","",Action_Function_Instances)
				module_variablemanager.translate(Action.Action_Instance,"Register")
				Action_Functions:=this.datastore_get("Action_Functions","",Array("Test","None"))
				if(this.isAction_Func(Action))
				{
					if(!Action_Functions.contains(Action.Action_Func))
					{
						module_includer.check_includer("module_actionmanager",Action.Action_Func)
						Action_Functions.push(Action.Action_func)	;Adds new Action Function to Registered Action functions
						this.config_set("Action_Functions","",Action_Functions)
					}
					Action_Func_Initialized:=this.datastore_get("Initialized","Action_Options",Array())
					if(!Action_Func_Initialized.contains(Action.Action_Func))
					{
						Action_Func_Initialized.push(Action.Action_Func)
						this.datastore_set("Initialized","Action_Options",Action_Func_Initialized)
						options:=this.runAction(Action,this.Module_eventinfo("Initialize","Initialize"))
						Action_Options:=this.datastore_get("Action_Options","",Array())
						if(isobject(options))
						{
							Loop % options.maxindex()
							{
								optionlist:=this.datastore_get(options[A_Index],"Action_Options",Array())
								optionlist.push(Action.Action_Func)
								this.datastore_set(options[A_Index],"Action_Options",optionlist)
								if(!Action_Options.contains(options[A_Index]))
									Action_Options.push(options[A_Index])
							}
						}
						else
						{
							Loop, Parse, options , |
							{
								optionlist:=this.datastore_get(A_Loopfield,"Action_Options",Array())
								optionlist.push(Action.Action_Func)
								this.datastore_set(A_Loopfield,"Action_Options",optionlist)
								if(!Action_Options.contains(A_Loopfield))
									Action_Options.push(A_Loopfield)
							}
						}
						this.datastore_set("Action_Options","",Action_Options)
					}
				}
				else if(Action_Functions.contains(Action.Action_Func))
				{
					this.unreg(Action)
					continue
				}
			}
			output:=this.isAction_Func(Action) or output ? 1 : 0
		}
		return output
	}
	unreg(Actions*)	{
		Action_Functions:=this.datastore_get("Action_Functions","",Array())
		for index,Action in Actions
		{
			if(!isobject(Action))	;Ensures Action is parsed
				Action:=this.parseAction(Action)
			if(!module_dependency.removeDependent("module_actionmanager",Action.Action_Func))
				continue
			if(Action_Functions.contains(Action.Action_Func))
				Action_Functions.removeAt(Action_Functions.indexOf(Action.Action_Func))
			Action_Options:=this.datastore_get("Action_Options","",Array())
			Loop % Action_Options.MaxIndex()
			{
				optionlist:=this.datastore_get(Action_Options[A_Index],"Action_Options",Array())
				if(optionlist.contains(Action.Action_Func))
				{
					optionlist.removeAt(optionlist.indexOf(Action.Action_Func))
					this.datastore_set(Action_Options[A_Index],"Action_Options",optionlist)
				}
			}
		}
		this.config_set("Action_Functions","",Action_Functions)
	}
	isAction_Func(Action)	{
		if(this.hook(A_thisFunc,Action))
			return  this.hook_value(A_thisFunc)
		if(!isobject(Action))
			action:=this.parseAction(Action)
		return this.module_func_namespace_exists("Action",Action.Action_Func)
	}
	parseAction(Action,allowdefaultaction:=1)	{
		if(this.hook(A_thisFunc,Action,allowdefaultaction))
			return  this.hook_value(A_thisFunc)
		output:=array()
		if(isobject(Action))
		{
			if(Action.Action_Instance != "" and Action.Action_func != "" and Action.Action_Info != "")
				return Action
			Action:=Action.Action_Instance
		}
		While (SubStr(Action,0) = "`n" or SubStr(Action,0) = "`r")
		{
			StringTrimRight, Action, Action, 1
			Action=%Action%
		}
		Action=%Action%
		output.Action_Instance:=Action
		StringgetPos, pos,Action,%A_SPace%
		if(ErrorLevel == 0)
		{
			action_func:=SubStr(Action,1,pos)
			StringLower action_func, action_func, T
			output.Action_func:=action_func
			pos:=pos+2
			output.Action_Info:=SubStr(Action,pos)
		}
		else
		{
			StringLower Action, Action, T
			output.Action_func:=Action
		}
		if(!this.isAction_Func(output) and allowdefaultaction)
			output.Action_func:=this.datastore_get("Default_Action_Function","","None")
			else
			this.reg(output)
		return output
	}
	runAction(Action,Eventinfo:="Execute",event_data:="")	{
		if(this.hook(A_thisFunc,Action,Eventinfo,event_data))
			return  this.hook_value(A_thisFunc)
		if(!isobject(Eventinfo))
				Eventinfo:=this.Module_eventinfo("Manual",Eventinfo,event_data)
		if(!isobject(Action) or Action.Action_func == "")
			Action:=this.parseAction(Action)
		actionfunc:=Action.Action_func
		if(this.isAction_Func(Action))
		{
			Action_Info:=this.module_format_toArray(Action.Action_Info)
			module_dependency.beginDependentBuild("module_actionmanager",actionfunc)
			returnval:=this.module_func_namespace_exec("Action",actionfunc,Action_Info,Eventinfo)
			module_dependency.endDependentBuild()
			return returnval
		}
	}		
	execute(Action,Eventinfo)	{
		if(this.hook(A_thisFunc,Action,Eventinfo))
			return  this.hook_value(A_thisFunc)
		if(!isobject(Eventinfo))
			Eventinfo:=this.Module_eventinfo(this.__Class, Eventinfo)
		notifierlock:=module_guihelper.Notifier_aggregate()
		;Parses Action chain by `, and returns final output.
		ifinstring, Action, ```,
		{
			Loop,Parse,Action,```,
				out:=this.execute(A_Loopfield,Eventinfo)
			module_guihelper.Notifier_aggregate(notifierlock)
			return out
		}
		Action = %Action%
		Action:=module_variablemanager.translate(Action,Eventinfo)
		output:= this.runAction(Action,Eventinfo)
		module_guihelper.Notifier_aggregate(notifierlock)
		return output
	}
	wizard(returnfunction:="",additionalvar1:="",additionalvar2:="")	{
		if(this.hook(A_thisFunc,returnfunction,additionalvar1,additionalvar2))
			return  this.hook_value(A_thisFunc)
		static ginfocache
		;Sends Action Wizard results to return function
		if(isobject(ginfocache))
		{
			ginfo:=ginfocache
			ginfocache:=""
			ginfo.Action_Info:=returnfunction,			Action_InfoString:=this.module_format_toString(returnfunction)
			ginfo.Action_Instance:=ginfo.Action_func " " Action_InfoString,		ginfo.template:="ActionWizard"
			module_guihelper.template_exec(ginfo.returnfunction,ginfo,ginfo.additionalvar1,ginfo.additionalvar2)
			return
		}
		Action_Options_Wizard:=this.datastore_get("Wizard","Action_Options",Array())
		;Handles Wizard Dropdown gui selected Action
		if(isobject(returnfunction))
		{
			ginfocache:=returnfunction,			ginfocache.Action_func:=ginfocache.vDropDownlist1
			;checks if an action was selected for the Wizard to use. if found then runs that action's wizard.
			if(returnfunction.GuiAction == "Button1" and Action_Options_Wizard.contains(ginfocache.Action_func))
			{
				possibleAction_Info:=this.runAction(ginfocache,"Wizard")
				;Checks if Action's Wizard directly returned a value.
				if(possibleAction_Info != "" or isobject(possibleAction_Info))
					this.wizard(possibleAction_Info)
				return
			}
			this.wizard("")
			return
		}
		;Creates Wizard Dropdown Gui
		Loop % Action_Options_Wizard.MaxIndex()
		{
			actionlist.="|" Action_Options_Wizard[A_Index]
		}
		ginfo:={Windowtitle: "Action Wizard",Button1: "Select",groupbox1: "Select Action",returnfunction: returnfunction,AdditionalVar1: AdditionalVar1,AdditionalVar2: AdditionalVar2,DropDownList1: actionlist,template:"ActionWizard"}
		if(Action_Options_Wizard.length() == 0)
		{
			Msgbox, Unfortunately there are currently no registered Action Functions that support the Wizard.
			module_guihelper.template_exec(returnfunction,ginfo,additionalvar1,additionalvar2)
			return
		}
		module_guitemplate.OneButtonDropdown(A_thisfunc,ginfo)
	}
	Editor(returnfunction, Action:="",additionalvar1:="",additionalvar2:="")	{
		if(this.hook(A_thisFunc,returnfunction,action,additionalvar1,additionalvar2))
			return  this.hook_value(A_thisFunc)
		if(isobject(returnfunction))
		{
			if(returnfunction.Template == "editor")
			{
				;Handles Editor Menu
				returnfunction.template:="ActionEditor",				returnfunction.Action_Instance:=returnfunction.vEdit1
				if(returnfunction.GuiAction == "Button1")
				{
					;Done Button
					module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.AdditionalVar1,returnfunction.AdditionalVar2)
					return
				}
				if(returnfunction.GuiAction == "Button3")
				{
					;Opens Action Wizard
					this.wizard(A_thisfunc,returnfunction)
					return
				}
				if(returnfunction.GuiAction == "Button2")
				{
					;Opens Variable Wizard
					module_variablemanager.wizard(A_thisfunc,returnfunction)
					return
				}
				;Undefined Gui Action
				returnfunction.Action_Instance:=returnfunction.OriginalAction_Instance
				module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.AdditionalVar1,returnfunction.AdditionalVar2)
				return
			}
			else if(returnfunction.GuiAction == "Button1")
			{

				if(action.GuiAction == "Button3")
				{
					;Handles Action Wizard
					if(Action.Edit1 == "")
						Action.Edit1:=Returnfunction.Action_Instance
					else
					{
						msgbox, 3,Action Editor,Do you want this action to be ran after the current action? `n(No will replace the current action)
						ifmsgbox, Yes
							Action.Edit1.= "``,`n" Returnfunction.Action_Instance
						ifmsgbox, No
							Action.Edit1:=Returnfunction.Action_Instance	
					}
				}
				else if(action.GuiAction == "Button2")
				{
					;Handles Variable Wizard
					varinstance:=returnfunction.Var_Instance
					module_guihelper.Clipboard_set(varinstance)
					TrayTip, Variable Wizard, Variable set to Clipboard`n %varinstance%, 5
				}
			}
			module_guitemplate.editor(A_thisfunc,action)
			return
		}
		;Creates Initial GuiInfo
		ginfo:={groupbox1: "Edit Action", Button1: "Done",Button2: "Variable Wizard", Button3: "Action Wizard", Button4_hide: 1, Edit1: Action, OriginalAction_Instance: Action, Windowtitle: "Action Editor",returnfunction: returnfunction,AdditionalVar1:additionalvar1, AdditionalVar2:AdditionalVar2}
		module_guitemplate.editor(A_thisfunc,ginfo)
	}
	module_configure(GuiInfo:="")	{
		if(this.hook(A_thisFunc,GuiInfo))
			return  this.hook_value(A_thisFunc,GuiInfo)
		if(isobject(GuiInfo))
		{
			if(GuiInfo.GuiAction == "GuiClose")
			{
				module_manager.module_configure()
				return
			}
			if(this.isAction_Func(GuiInfo.vDropDownlist1))
				this.config_set("Default_Action_Function","",GuiInfo.vDropDownlist1)
			if(GuiInfo.GuiAction == "Button2")
			{
				InputBox, newAction , New Action, New Action Function Name:
				if(!ErrorLevel)
					this.reg(newAction)
			}
			else if(GuiInfo.GuiAction == "Button1")
			{
				module_manager.module_configure()
				return
			}
		}
		Action_Functions:=this.datastore_get("Action_Functions","",Array("Test","None"))
		Loop % Action_Functions.maxindex()
			actionlist.="|" Action_Functions[A_Index]
		ginfo:={Button2: "Add Action Function", Button1: "Done", DropDownList1: actionlist, DropDownList1_ChooseString: this.datastore_get("Default_Action_Function","","None"), Groupbox1: "Select Default Action", Windowtitle: "Action Manager"}
		module_guitemplate.TwoButtonDropdown(A_thisfunc,ginfo)
	}
	module_dependency(Directive,DependentName)	{
		if(Directive == "add")
			return this.reg(DependentName)
		if(directive == "remove")
			return this.unreg(DependentName)
	}
	core_file()	{
		return A_LineFile
	}
}