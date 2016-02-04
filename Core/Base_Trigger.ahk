Class module_base_trigger extends module_base {
	static module_base_trigger_module_about:="Base Trigger is a base for trigger modules to be built off of. It consolidates a trigger event into a string then associates Actions with that trigger string. `nBy Electrocret"
	core_file()	{
		return A_LineFile
	}
	Trigger_set_Priority_Index_Datastore(Newdatastore:=""){
		static datastore_Trigger:=Array()
		if(Newdatastore == "")
			return datastore_Trigger[ this.__Class] == ""? "file": datastore_Trigger[ this.__Class]
		if(this.datastore_isdatastore(Newdatastore))
		{
			StringLower, Newdatastore,Newdatastore
			trig_name_index:=this.datastore_get("Index","Trigger",Array())
			Olddatastore:=datastore_Trigger[ this.__Class] == ""? "file": datastore_Trigger[ this.__Class]
			loop % trig_name_index.MaxIndex()
			{
				this.datastore_transfer_var(Olddatastore,Newdatastore,trig_name_index[A_Index],"Trigger")
			}
			datastore_Trigger[ this.__Class]:=Newdatastore
		}
	}
	;Performs Actual Trigger registration -This should be called by implemented registration functions
	trigger_reg(trigger_name, Action,trigpriority:=0,trig_name_already_naturalized:=0){
		if(this.hook(A_thisFunc,trigger_name,Action,trigpriority))
			return  this.hook_value(A_thisFunc)
		if trigpriority is not number
			return 0
		if(isobject(trigger_name))
		{
			output:=0
			loop % trigger_name.MaxIndex()
			{
				if(this.trigger_reg(trigger_name[A_Index],Action,trigpriority,trig_name_already_naturalized))
					output:=1
			}
			return output
		}
		trigger_name:=trig_name_already_naturalized? trigger_name : this.module_format_naturalize(trigger_name)
		if(!this.trigger_isreg(trigger_name,Action,trigpriority,1))
		{
			module_actionmanager.reg(Action)
			triggeractions:=this.datastore_get(trigger_name "_" trigpriority,"Trigger",Array())
			triggeractions.insert(Action)
			this.datastore_Set(trigger_name "_" trigpriority,"Trigger",triggeractions)
			if(this.datastore_Get("priority_lowest","Trigger",0) > trigpriority)
				this.datastore_Set("priority_lowest","Trigger",trigpriority)
			if(this.datastore_Get("priority_highest","Trigger",0) < trigpriority)
				this.datastore_Set("priority_highest","Trigger",trigpriority)
			trig_name_priorities:=this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore())
			if(!trig_name_priorities.contains(trigpriority))
			{
				trig_name_priorities.push(trigpriority)
				this.datastore_set(trigger_name,"Trigger",trig_name_priorities,this.Trigger_set_Priority_Index_Datastore())
			}
			trig_name_index:=this.datastore_Get("Index","Trigger",Array())
			if(!trig_name_index.contains(trigger_name))
			{
				trig_name_index.push(trigger_name)
				this.datastore_set("Index","Trigger",trig_name_index)
			}
		}
		return 1
	}
	;Performs Actual internal Action Trigger unregistration -This should be called by implemented unregistration functions
	trigger_unreg(trigger_name, Action,trigpriority:="",trig_name_already_naturalized:=0){
		if(this.hook(A_thisFunc,trigger_name,Action,trigpriority))
			return  this.hook_value(A_thisFunc)
		if(isobject(trigger_name))
		{
			output:=0
			loop % trigger_name.MaxIndex()
			{
				if(this.trigger_unreg(trigger_name[A_Index],Action,trigpriority,trig_name_already_naturalized))
					output:=1
			}
			return output
		}
		trigger_name:=trig_name_already_naturalized? trigger_name : this.module_format_naturalize(trigger_name)
		if trigpriority is not number
		{
			trigpriority:=this.Trigger_Action_priority(trigger_name,Action,1)
		}
		if(this.trigger_isreg(trigger_name,Action,trigpriority,1) and trigpriority != "")
		{
			triggeractions:=this.datastore_get(trigger_name "_" trigpriority ,"Trigger",Array())
			triggeractions.removeAt(triggeractions.indexof(Action))
			if(triggeractions.length() == 0)
			{
				this.datastore_set(trigger_name "_" trigpriority, "Trigger","")
				trig_name_priorities:=this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore())
				trig_name_priorities.RemoveAt(trig_name_priorities.IndexOf(Trigpriority))
				if(trig_name_priorities.length() == 0)
				{
					this.datastore_set(trigger_name,"Trigger","",this.Trigger_set_Priority_Index_Datastore())
					trig_name_index:=this.datastore_Get("Index","Trigger",Array())
					trig_name_index.removeAt(trig_name_index.indexof(trigger_name))
					this.datastore_set("Index","Trigger",trig_name_index,this.Trigger_set_Priority_Index_Datastore())
				}
				else
					this.datastore_set(trigger_name,"Trigger",trig_name_priorities,this.Trigger_set_Priority_Index_Datastore())
			}
			else
				this.datastore_set(trigger_name "_" trigpriority, "Trigger",triggeractions)
			return 1
		}
		return 0
	}
	;Performs Actual Check if a trigger_name/Action/Trigpriority is registered. It can be as specific or vague as you like depending on if Action or Trigpriority are provided.
	trigger_isreg(trigger_name,Action:="",trigpriority:="",trig_name_already_naturalized:=0){
		if(this.hook(A_thisFunc,trigger_name,Action,trigpriority))
			return  this.hook_value(A_thisFunc)
		trigger_name:=trig_name_already_naturalized? trigger_name : this.module_format_naturalize(trigger_name)
		if(this.datastore_Get("Index","Trigger",Array()).contains(trigger_name))
		{
			if(action == "")
			{
				if trigpriority is not number
					return 1
				return this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore()).contains(trigpriority)
			}
			else
			{
				if trigpriority is number
					return this.datastore_get(trigger_name "_" trigpriority ,"Trigger",Array()).contains(Action) and this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore()).contains(trigpriority)
				trig_name_priorities:=this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore())
				loop % trig_name_priorities.MaxIndex()
				{
					if(this.datastore_get(trigger_name "_" trig_name_priorities[A_Index] ,"Trigger",Array()).contains(Action))
						return 1
				}
			}
		}
		return 0
	}
	;Returns an Array of all Triggers in the naturalized format.
	Trigger_Index()	{
		return this.datastore_Get("Index","Trigger",Array())
	}
	;Returns an Array of All the priority levels this Trigger has.
	Trigger_Priorities(trigger_name,trig_name_already_naturalized:=0)	{
		trigger_name:=trig_name_already_naturalized ? trigger_name : this.module_format_naturalize(trigger_name)
		return this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore())
	}
	;Returns the Priority level the specified Action has. Returns a blank string if Trigger_Name does not have Action.
	Trigger_Action_priority(trigger_name,Action,trig_name_already_naturalized:=0)	{
		trigger_name:=trig_name_already_naturalized? trigger_name : this.module_format_naturalize(trigger_name)
		trig_name_priorities:=this.datastore_get(trigger_name,"Trigger",Array(),this.Trigger_set_Priority_Index_Datastore())
		loop % trig_name_priorities.MaxIndex()
		{
			if(this.trigger_isreg(trigger_name,Action,trig_name_priorities[A_Index],1))
				return trig_name_priorities[A_Index]
		}
	}
	;Returns an array of All Actions at the specified Trigger_name and Priority level.
	Trigger_Actions(trigger_name,trigpriority,trig_name_already_naturalized:=0)	{
		trigger_name:=trig_name_already_naturalized ? trigger_name : this.module_format_naturalize(trigger_name)
		return this.datastore_get(trigger_name "_" trig_name_priorities[A_Index] ,"Trigger",Array())
	}
	;Fires a Trigger or list of triggers.
	trigger_fire(event_data_Or_Info,trigger_names*)	{
		notifierlock:=module_guihelper.Notifier_aggregate(),		trigger_list:=Array(),		trigger_nat_list:=Array(),		Trigger_Index:=this.Trigger_Index()
		for index,trigger_name in trigger_names
		{
			if(this.hook(A_thisFunc,event_data_Or_Info,trigger_name))
				continue
			if(isobject(trigger_name))
			{
				loop % trigger_name.MaxIndex()
					this.trigger_fire_list_build(trigger_list,trigger_nat_list,trigger_name[A_Index],Trigger_Index)
			}
			else
				this.trigger_fire_list_build(trigger_list,trigger_nat_list,trigger_name,Trigger_Index)
		}
		this.log_info(A_thisFunc,TriggerList)
		priority_current:=this.datastore_Get("priority_lowest","Trigger",0),		priority_highest:=this.datastore_Get("priority_highest","Trigger",0)
		while priority_current <= priority_highest
		{
			Thread, priority, %priority_current%
			this.datastore_set("priority_current","Trigger",priority_current)
			loop % trigger_list.MaxIndex()
			{
				if(!isobject(eventinfo%A_Index%))
					eventinfo%A_Index%:=this.Module_eventinfo(trigger_list[A_Index],"Execute",event_data_Or_Info)	
				this.trigger_fire_priority(trigger_nat_list[A_Index],priority_current,eventinfo%A_Index%)
			}
			priority_current++
		}
		module_guihelper.Notifier_aggregate(notifierlock)
	}
	trigger_fire_list_build(byref trigger_list,byref trigger_nat_list ,trigger_name,Trigger_Index)	{
		trigger_nat_name:=this.module_format_naturalize(trigger_name)
		if(Trigger_Index.contains(trigger_nat_name))
		{
			trigger_list.push(trigger_name)
			trigger_nat_list.push(trigger_nat_name)
		}
	}
	trigger_fire_priority(trigger_nat_name,trigpriority,eventinfo)	{
		triggeractions:=this.datastore_get(trigger_nat_name "_" trigpriority,"Trigger",Array())
		this.log_debug(A_thisFunc,triggeractions,"Pri" trigpriority "-")
		loop % triggeractions.MaxIndex()
		{
			module_actionmanager.execute(triggeractions[A_Index],eventinfo)
		}
	}
	trigger_loader(loadmode,instance,action)	{
		if(loadmode)
			this.trigger_reg(instance,action)
		else
			this.trigger_unreg(instance,action)
	}
	trigger_constructor()	{
		InputBox, string , Trigger String, Please Enter Trigger String:
		if(errorlevel == 0)
			module_triggermanager.construct(string)
		else
			module_triggermanager.construct()
		return
	}
	#include *i %A_ScriptDir%\Generated\Extension_base_trigger.ahk
}
