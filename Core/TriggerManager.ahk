Class module_triggermanager extends module_base{
static Triggermodules:=Array(), triggers:=array(),module_initialize_level:=8
static module_version:= 1.0
;static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/TriggerCore.ahk"
	static module_about:="Trigger Manager creates an easy interface with compatible Trigger Modules to create and edit Triggers. `nBy Electrocret"	
		core_file()	{
		return A_LineFile
	}
	reg(Trigger)	{
		if(this.hook(A_thisFunc,Trigger))
			return  this.hook_value(A_thisFunc)
		if(isobject(Trigger))
			Trigger:=Trigger.__Class
		StringLower Trigger, Trigger, T
		Triggermodules:=this.datastore_Get("TriggerModules","",Array())
		if(isfunc(Trigger ".trigger_loader") and isfunc(Trigger ".trigger_constructor")  and !Triggermodules.contains(Trigger))
				Triggermodules.push(Trigger)
		this.config_set("Triggermodules","",Triggermodules)
		return isfunc(Trigger ".trigger_loader") and isfunc(Trigger ".trigger_constructor")
	}
	module_init()	{
		;Inits
		this.datastore_set_Default_Datastore("this")
		this.datastore_Set("Category","module","Core")
		Loop % this.triggers.MaxIndex()
		{
			trigger:=this.triggers[A_Index]
			trigger_namespace:=this.module_format_naturalize(trigger,200)
			trigger_type:=this[trigger_namespace "_Type"]
			%trigger_type%.trigger_loader(1,this[trigger_namespace "_Instance"], this[trigger_namespace "_Action"])
		}
	}
	module_configure(guiInfo:="Configure",secondaryguiInfo:=""){
		if(this.hook(A_thisFunc,guiinfo,secondaryguiInfo))
			return  this.hook_value(A_thisFunc)
		if(isobject(guiInfo))
		{
			if(Guiinfo.Template == "manager")
			{
				;check is something was selected
				if(guiInfo.vListbox1 != "")
				{
					selected:=guiInfo.vListbox1
					;Edit Existing selected trigger Button
					if(GuiInfo.GuiAction == "Button2")
					{
						module_actionmanager.editor(A_thisFunc, this.configure_retrieveAction(selected) ,guiInfo)
						return
					}
					;Delete selected Trigger Button
					if(GuiInfo.GuiAction == "Button3")
					{	
						MsgBox, 4, , Are you sure you would like to Delete %selected%?
						IfMsgBox, Yes
							this.configure_delete(selected)
					}
				}
				;Create New Trigger Button
				if(GuiInfo.GuiAction == "Button1")
				{
					this.construct(A_thisFunc,GuiInfo)
					return
				}
				;Finished with Trigger Manager
				if(GuiInfo.GuiAction == "Button4" or GuiInfo.GuiAction == "GuiClose")
				{
					module_manager.module_configure()
					return
				}
			}
			else if(GuiInfo.Template == "ActionEditor")
				this.configure_updateAction(secondaryguiInfo.vListbox1,GuiInfo.Action_Instance)
		}
		Loop % this.triggers.MaxIndex()
			triggerlist.="|" this.triggers[A_Index] 
		if(triggerlist == "")
			triggerlist:="|"
		ginfo:={groupbox1: "Triggers",Button1: "New Trigger",Button2: "Edit Action", Button3: "Delete Trigger",Button4: "Done", Listbox1: triggerlist ,Windowtitle: "Trigger Manager"}
		module_guitemplate.manager(A_thisFunc,ginfo)
	}
	construct(returnfunction:="" , AdditionalVar1:="" , Additionalvar2:="")
	{
		if(this.hook(A_thisFunc,returnfunction,AdditionalVar1,AdditionalVar2))
			return  this.hook_value(A_thisFunc)
		static ginfocache
		if(isobject(ginfocache))
		{
			;return from trigger construct
			guiinfocache:=ginfocache
			ginfocache:=""
			guiinfocache.trigger_instance:=returnfunction
			if(returnfunction == "")
			{
				guiinfocache.template:="Construct"
				module_guihelper.template_exec(guiinfocache.returnfunction,guiinfocache,guiinfocache.additionalvar1,guiinfocache.additionalvar2)
				return
			}
			MsgBox, 4, , Do you want to use the Action Wizard?
			IfMsgBox, Yes
				module_actionmanager.wizard(A_thisfunc,guiinfocache)
			else IfMsgBox, No
				module_actionmanager.editor(A_thisFunc,"",guiinfocache)
			else
			{
				guiinfocache.template:="Construct"
				module_guihelper.template_exec(guiinfocache.returnfunction,guiinfocache,guiinfocache.additionalvar1,guiinfocache.additionalvar2)
			}
			return
		}
		if(isobject(returnfunction))
		{
			;return from Gui
			ginfocache:=""
			if(returnfunction.template == "OneButtonDropdown")
			{
				;Select button and item selected in dropdown.
				if(returnfunction.GuiAction == "Button1" and returnfunction.vDropdownlist1 != "")
				{
					trigtype:=returnfunction.vDropdownlist1
					returnfunction.trigger_type:=trigtype
					ginfocache:=returnfunction
					%trigtype%.trigger_constructor()
					return
				}
				;Unknown input goes to returnfunction
				returnfunction.template:="Construct"
				module_guihelper.template_exec(returnfunction.returnfunction,returnfunction,returnfunction.additionalvar1,returnfunction.additionalvar2)
				return
			}
			if(returnfunction.template == "ActionWizard" and returnfunction.GuiAction == "Button1")
			{
				module_actionmanager.editor(A_thisFunc,returnfunction.Action_Instance,AdditionalVar1)
				return
			}
			if(returnfunction.template == "ActionEditor" and returnfunction.guiAction == "Button1")
				this.configure_new(additionalvar1.trigger_type, additionalvar1.trigger_instance, returnfunction.Action_Instance)
			;Go to Return Function
			AdditionalVar1.template:="Construct"
			module_guihelper.template_exec(AdditionalVar1.returnfunction,AdditionalVar1,AdditionalVar1.additionalvar1,AdditionalVar1.additionalvar2)

			return
		}
		;Checks For any Modules that are module_triggermanager compatible and Registers them.
		Modules:=module_manager.datastore_Get("Modules","Core")
		Loop % Modules.MaxIndex()
			this.reg(Modules[A_Index])
		;Makes Registered Triggers into a list for the dropdown menu
		Loop % this.Triggermodules.MaxIndex()
			types.="|" this.Triggermodules[A_Index]
		ginfo:={groupbox1: "Trigger Type", Button1: "Select", DropdownList1: types,Windowtitle: "Select Trigger Type", returnfunction: returnfunction,AdditionalVar1: additionalvar1,AdditionalVar2: additionalvar2}
		if(this.Triggermodules.length() == 0)
		{
			Msgbox, Unfortunately there are currently no registered Triggers.
			module_guihelper.template_exec(returnfunction,ginfo,additionalvar1,additionalvar2)
			return
		}
		module_guitemplate.OneButtonDropdown(A_thisFunc,ginfo)
		return
	}
	listtriggers()
	{
		if(this.hook(A_thisFunc))
			return  this.hook_value(A_thisFunc)
		output:="Triggers:"
		Loop % this.Triggermodules.MaxIndex()
			output.="`n" this.Triggermodules[A_Index] 
		msgbox,,Triggers, %output%
	}
	configure_updateAction(trigger, Action)
	{
		if(this.hook(A_thisFunc,trigger,action))
			return  this.hook_value(A_thisFunc)
		trigger_namespace:=this.module_format_naturalize(trigger,200)
		;Update Trigger with Trigger Module
		trigger_type:=this.datastore_Get("Type",trigger_namespace)
		%trigger_type%.trigger_loader(0,this.datastore_Get("Instance",trigger_namespace), this.datastore_Get("Action",trigger_namespace))
		%trigger_type%.trigger_loader(1,this.datastore_Get("Instance",trigger_namespace), Action)
		;Update stored Action for Trigger in module_triggermanager
		this.config_set("Action",trigger_namespace,Action)
	}
	configure_retrieveAction(trigger)
	{
		if(this.hook(A_thisFunc,trigger))
			return  this.hook_value(A_thisFunc)
		trigger_namespace:=this.module_format_naturalize(trigger,200)
		return this.datastore_Get("Action",trigger_namespace)
	}
	configure_delete(trigger)
	{
		if(this.hook(A_thisFunc,trigger))
			return  this.hook_value(A_thisFunc)
		if(this.triggers.contains(trigger))
		{
			;Remove Trigger from Triggers array in module_triggermanager then saves it
			this.triggers.removeAt(this.triggers.indexof(trigger))
			this.config_set("triggers")
			;Removes Trigger from Trigger Module
			trigger_namespace:=this.module_format_naturalize(trigger,200)
			trigger_type:=this.datastore_Get("Type",trigger_namespace)
			%trigger_type%.trigger_loader(0,this.datastore_Get("Instance",trigger_namespace), this.datastore_Get("Action",trigger_namespace))
			;Removes Trigger from module_triggermanager
			this.config_remove("Instance",trigger_namespace)
			this.config_remove("Type",trigger_namespace)
			this.config_remove("Action",trigger_namespace)
			module_dependency.removeDependent("module_triggermanager",trigger)
		}
	}
	configure_new(insert_type, insert_instance, Action:="")
	{
		if(this.hook(A_thisFunc,insert_type,insert_instance,Action))
			return  this.hook_value(A_thisFunc)
		if(this.reg(Insert_type))
		{
			;Creates Trigger ID and stores it in 'trigger' variable
			if(isfunc(insert_type ".module_trigger_display"))
				instancedisplay:=%insert_type%.module_trigger_display(insert_instance)
			else
				instancedisplay:=this.module_format_toString(insert_instance)
			trigger:=insert_type "-" instancedisplay
			StringReplace, trigger, trigger, |, `,
			;Ensures Trigger ID is unique
			if(this.triggers.contains(trigger))
			{
				notunique:=1
				while(notunique)
				{
					trig_check:=trigger a_index
					if(this.triggers.contains(trig_check))
					{
						trigger:=trig_check
						notunique:=0
					}
				}
			}
			;Adds trigger and stores info
			this.triggers.push(trigger)
			this.config_set("triggers")
			trigger_namespace:=this.module_format_naturalize(trigger,200)
			this.config_set("Instance",trigger_namespace,insert_instance)
			this.config_set("Type",trigger_namespace,insert_type)
			this.config_set("Action",trigger_namespace,Action)
			module_dependency.addDependent("module_manager",insert_type,"module_triggermanager",trigger)
			;Loads Trigger with Trigger Module
			%insert_type%.trigger_loader(1,insert_instance, Action)
		}
	}
	#include *i %A_ScriptDir%\Generated\Extension_triggermanager.ahk
	module_dependency(Directive,DependentName)
	{
		if(Directive == "remove")
			this.configure_delete(DependentName)
	}
}
/*
	Trigger Manager - Trigger Compatibility functions:
	trigger_construct() - Used by trigger manager to create new triggers.
	trigger_loader(loadmode, Instance, Action) - Used to Initialize Trigger Action
	trigger_display(Instance)  -Used to make Instance Easily Displayable in Manager
*/