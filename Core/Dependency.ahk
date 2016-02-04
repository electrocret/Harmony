/*
	Dependent_<DependentHandler-DependentName> - List of all Parents this dependent depends on
	Parent_<ParentHandler-ParentName> -List of Dependents that depend on this Parent
	Dependent_Index - List of all Dependents
	Parent_Index -List of all Parents
	
*/
class module_dependency extends module_base{
	static module_about:="Dependency records and tracks dependencies among scripts on one another, and ensures that the dependencies are being fulfilled.`nCreated by Electrocret"
	static module_version:= 1.0
	static module_datastore_default:="file"
	static DependentBuildHandler,DependentBuildName,DependentBuildArray:=Array(),module_initialize_level:=2
	#include *i %A_ScriptDir%\Generated\Extension_dependency.ahk
	core_file()	{
		return A_LineFile
	}
	module_init()	{
		Parent_Index:=this.datastore_get("Parent_Index","",Array())
		Loop % Parent_Index.MaxIndex()
		{
			dependent:=this.parseDependent(Parent_Index[A_Index])
			this.addDependent(dependent.Handler,dependent.Name,"init","init",1)
		}
	}
	module_postinit(){
		Handler_Index:=this.datastore_get("Handler_Index","",Array("module_extensionmanager"))
		Loop % Handler_Index.MaxIndex()
			this.execDependent(Handler_Index[A_Index],"","cleanup")
	}
	configuration_lock(LockedDependentHandler,LockedDependentName,state:=1)	{
		if(state == -1)
		{
			LockedDependentHandler=%LockedDependentHandler%
			LockedDependentName=%LockedDependentName%
			StringLower, LockedDependentHandler,LockedDependentHandler
			StringLower, LockedDependentName,LockedDependentName
			if(this.datastore_get(this.module_format_naturalize(LockedDependentHandler "#" LockedDependentName),"Parents",Array()).contains("#" LockedDependentHandler "#" LockedDependentName))
				state:=0
			else
				state:=1
		}
		if(state)
			this.addDependent(LockedDependentHandler, LockedDependentName,"#" LockedDependentHandler,LockedDependentName)
		else
			this.removeDependent("#" LockedDependentHandler, LockedDependentName,1)
	}
	beginDependentBuild(DependentHandler,DependentName)	{
		if(!(this.DependentBuildHandler == "" and this.DependentBuildName == ""))
		this.DependentBuildArray.push(this.DependentBuildHandler "#" this.DependentBuildName)
		this.DependentBuildHandler:=DependentHandler
		this.DependentBuildName:=DependentName
	}
	endDependentBuild()	{
		lastbuild:=this.DependentBuildArray.pop()
		if(lastbuild == "")
		{
			this.DependentBuildHandler:="", this.DependentBuildName:=""
		}
		else
		{
			StringgetPos, pos,lastbuild,#
			this.DependentBuildHandler:=SubStr(lastbuild,1,pos)
			pos:=pos+2
			this.DependentBuildName:=SubStr(lastbuild,pos)
		}
	}
	configmode_dependency(DependentHandler:="",DependentName:="",ParentHandler:="",ParentName:="")	{
		static datastore_dependenthandlers, datastore_dependentnames
		if(DependentHandler == "" and DependentName == "" and ParentHandler == "" and ParentName == "")
		{
			if(!module_manager.Core_configmode(-2).contains("reload"))
			{
				Loop % datastore_dependenthandlers.MaxIndex()
				{
					notfoundlist.= "`n" datastore_dependenthandlers[A_Index] "#" datastore_dependentnames[A_Index]
				}
				Msgbox, 4,Dependent Not Found,Error: Dependencies not found for the following items.`nWould you like to remove them? `n (they likely will not work properly if you keep them.)`n%notfoundlist%
				ifmsgbox Yes
				{
					Dependencies:=this.datastore_get("Dependent_Index","",Array())
					Loop % datastore_dependenthandlers.MaxIndex()
					{
						this.removeDependent(datastore_dependenthandlers[A_Index],datastore_dependenthandlers[A_Index],2)
						this.execDependent(datastore_dependenthandlers[A_Index],datastore_dependenthandlers[A_Index],"remove")
					}
				}
			}
			return
		}
		if(!module_manager.Core_configmode(-1))
		{
			Msgbox, 4,Dependent Not Found,Error: Dependent for %DependentHandler%#%DependentName% not found. `nCould Not find: %ParentHandler%#%ParentName%.`nWould you like to remove %DependentHandler%#%DependentName%? `n (It likely will not work properly.)
			ifmsgbox Yes
			{
				this.removeDependent(DependentHandler,DependentName,2)
				this.execDependent(DependentHandler,DependentName,"remove")
			}
		}
		else if(!module_manager.Core_configmode(-2).contains("reload"))
		{
			datastore_dependenthandlers:=datastore_dependenthandlers == ""?Array() : datastore_dependenthandlers
			datastore_dependentnames:=datastore_dependentnames == "" ?Array() : datastore_dependentnames
			datastore_dependenthandlers.push(DependentHandler)
			datastore_dependentnames.push(DependentName)
			module_manager.Core_configmode("module_dependency.configmode_dependency")
		}
	}
	execDependent(DependentHandler,DependentName,Directive)	{
		if(substr(DependentHandler,1,1) == "#")
			return 1
		return %DependentHandler%.module_dependency(Directive,DependentName)	
	}
	addDependent(ParentHandler,ParentName,DependentHandler:="",DependentName:="",skipstorage:=0)	{
		this.module_checkinit()
		if(DependentHandler == "" and DependentName == "")
		{
			if(this.DependentBuildHandler == "" and this.DependentBuildName == "")
				return ;No Dependencies are being built
			DependentHandler:=this.DependentBuildHandler
			DependentName:=this.DependentBuildName
		}
		ParentHandler=%ParentHandler%
		ParentName=%ParentName%
		DependentHandler=%DependentHandler%
		DependentName=%DependentName%
		StringLower, DependentHandler,DependentHandler
		StringLower, DependentName,DependentName
		StringLower, ParentName,ParentName
		StringLower, ParentHandler,ParentHandler
		if((DependentHandler == "module_manager" and DependentName == "module_dependency")or (ParentHandler == DependentHandler and ParentName == DependentName))
			return
		if(this.execDependent(ParentHandler,ParentName,"add"))
		{
			if(!skipstorage)
			{
				;Keeps list of Handlers
				Handler_Index:=this.datastore_get("Handler_Index","",Array("module_extensionmanager"))
				if( substr(ParentHandler,1,1) != "#" and !Handler_Index.contains(ParentHandler))
				{
					Handler_Index.push(ParentHandler)
					this.config_set("Handler_Index","",Handler_Index)
				}
				if(substr(DependentHandler,1,1) != "#" and !Handler_Index.contains(DependentHandler))
				{
					Handler_Index.push(DependentHandler)
					this.config_set("Handler_Index","",Handler_Index)
				}
				;Records Parent
				Parent_Index:=this.datastore_get("Parent_Index","",Array())
				if(!Parent_Index.contains(ParentHandler "#" ParentName))
				{
					Parent_Index.push(ParentHandler "#" ParentName)
					this.config_set("Parent_Index","",Parent_Index)
				}
				;Records Dependent
				Dependent_Index:=this.datastore_get("Dependent_Index","",Array())
				if(!Dependent_Index.contains(DependentHandler "#" DependentName))
				{
					Dependent_Index.push(DependentHandler "#" DependentName)
					this.config_set("Dependent_Index","",Dependent_Index)
				}
				;Records Dependent to Parent
				parent_nat:=ParentHandler "#" ParentName
				parent_dependents:=this.datastore_get(parent_nat,"Parents",Array())
				if(!parent_dependents.contains(DependentHandler "#" DependentName))
				{
					parent_dependents.push(DependentHandler "#" DependentName )
					this.config_set(parent_nat,"Parents",parent_dependents)
				}
				;Records Parents for this Dependent
				dependent_nat:=DependentHandler "#" DependentName
				dependent_parents:=this.datastore_get(dependent_nat,"Dependents",Array())
				if(!dependent_parents.contains(ParentHandler "#" ParentName))
				{
					dependent_parents.push(ParentHandler "#" ParentName )
					this.config_set(dependent_nat,"Dependents",dependent_parents)
				}
			}
		}
		else
			this.configmode_dependency(DependentHandler,DependentName,ParentHandler,ParentName)
	}
	removeDependent(DependentHandler,DependentName:="",forceremove:=0)	{
		static internal_forceremove:=0
		;msgbox %DependentHandler%-%DependentName%
		this.module_checkinit()
		DependentHandler=%DependentHandler%
		DependentName=%DependentName%
		StringLower, DependentHandler,DependentHandler
		StringLower, DependentName,DependentName
		remove_check:=internal_forceremove or forceremove?1:0
		parent_dependents:=this.getDependents(DependentHandler,DependentName)
		if(forceremove != 3 and parent_dependents.contains("#" DependentHandler "#" DependentName))
		{
			this.removeDependent("#" DependentHandler, DependentName,1)
			parent_dependents:=this.getDependents(DependentHandler,DependentName)
		}
		;msgbox % this.module_format_toString(parent_dependents) ;Testing
		if(!remove_check and parent_dependents.length() > 0)
		{
			loop % parent_dependents.MaxIndex()
			{
				if(substr(parent_dependents[A_Index],1,1) != "#")
					dependentlist.="`n "parent_dependents[A_Index]
			}
			Msgbox, 3,Dependencies Found!,Items Dependent on '%DependentHandler%#%DependentName%' were found. `n Would you like to remove the items dependent on this?`n%dependentlist%`n`n(Note: By selecting No, these items will remain, however they may quit working or add '%DependentHandler%#%DependentName%' back)
			ifmsgbox Cancel
				return 0
			ifmsgbox Yes
				forceremove:=2
		}
		if(forceremove == 2)
		{
			;Sends command to remove Dependents that rely on this Dependent
			internal_forceremove:=1
			loop % parent_dependents.MaxIndex()
			{
				dependent:=this.parseDependent(parent_dependents[A_Index])
				this.execDependent(dependent.Handler,dependent.Name,"remove")
			}
			internal_forceremove:=0
		}
		dependent_nat:=DependentHandler "#" DependentName
		;dependent_nat:=this.module_format_naturalize(DependentHandler "#" DependentName)
		if(forceremove != 3)
		{
			Dependent_Index:=this.datastore_get("Dependent_Index","",Array())
			if(Dependent_Index.contains(DependentHandler "#" DependentName))
			{
				;Removes from Dependent Index
				Dependent_Index.removeAt(Dependent_Index.indexOf(DependentHandler "#" DependentName))
				this.config_set("Dependent_Index","",Dependent_Index)
			}
				;Removes itself from the parent lists that this dependent is on.
				dependent_parents:=this.datastore_Get(dependent_nat,"Dependents")
				loop % dependent_parents.MaxIndex()
				{
					parent_nat:=dependent_parents[A_Index]
					;parent_nat:=this.module_format_naturalize(dependent_parents[A_Index])
					parent:=this.datastore_Get(parent_nat,"Parents")
					if(parent.contains(DependentHandler "#" DependentName))
					{
						parent.removeAt(parent.indexOf(DependentHandler "#" DependentName))
						if(parent.length() == 0)	;Checks if This Parent No longer is being depended on.
						{ ;Not being Depended on. - So it is removed	
							pdependent:=this.parseDependent(dependent_parents[A_Index])
							this.removeDependent(pdependent.Handler,pdependent.Name,3)
						}
						else
							this.config_set(parent_nat,"Parents","",parent) ;Being Depended On
					}
				}
				;Removes Dependent List
				this.config_remove(dependent_nat,"Dependents")
		}
		;Removes from Parent Index
		Parent_Index:=this.datastore_get("Parent_Index","",Array())
		if(Parent_Index.contains(DependentHandler "#" DependentName))
		{
			Parent_Index.removeAt(Parent_Index.indexOf(DependentHandler "#" DependentName))
			this.config_set("Parent_Index","",Parent_Index)
			this.config_remove(dependent_nat, "Parents")
			this.execDependent(DependentHandler,DependentName,"remove")
		}
		return 1
	}
	getDependents(ParentHandler,ParentName:="",toutput:="")	{
		if(ParentName == "")
			parent_nat:=ParentHandler
		else
			parent_nat:=ParentHandler "#" ParentName
		parent_dependents:= this.datastore_get(parent_nat,"Parents")
		output:=toutput == ""?Array():toutput
		loop % parent_dependents.MaxIndex()
		{
			if(!output.contains(parent_dependents[A_Index]))
			{
				output.push(parent_dependents[A_Index])
				if(parent_dependents[A_Index] != parent_nat)
				{
					output:=this.getDependents(parent_dependents[A_Index],"",output)
				}
			}
		}
		return output
	}
	parseDependent(Dependent)	{
		output:=Array()
		Output.Dependents:=Dependent
		StringgetPos, pos,dependent,#
		if(!Errorlevel)
		{
			Output.Handler:=SubStr(dependent,1,pos)
			pos:=pos+2
			Output.Name:=SubStr(dependent,pos)
		}
		else
			Output.Handler:=dependent
		return Output
	}
	Action(ActionFuncs*)	{
		for index,ActionFunc in ActionFuncs
			this.addDependent("module_actionmanager", ActionFunc)
	}
	Variable(VariableFuncs*)	{
		for index,VariableFunc in VariableFuncs
			this.addDependent("module_variablemanager", VariableFunc)
	}
	Module(ModuleNames*)	{
		for index,ModuleName in ModuleNames
			this.addDependent("module_manager", module_manager.Core_format_module_natural(ModuleName))
		return 1
	}
	Include(Name,Include_Type,DownloadURL:="")	{
		if(!module_includer.isIncludeable(Name,Type_include) and DownloadURL != "")
		{
			downloadlocation:=module_includer.include_file(Name,Include_Type)
			DownloadURL:=this.module_DDLLink(DownloadURL)
			UrlDownloadToFile, %DownloadURL%, %downloadlocation%
			this.module_check_valid(Name,downloadlocation)
		}
		this.addDependent("module_includer",Include_Type "#" Name)
	}
	Extension(ModuleName,ExtensionName,DownloadURL:="",not_dependent:=0)	{
		ModuleName:=module_manager.Core_format_module_natural(ModuleName)
		if(module_manager.ismodule(ModuleName))
		{
			if(!%ModuleName%.extension_check_exists(ExtensionName) and DownloadURL != "")
			{
				downloadlocation:=%ModuleName%.extension_file(ExtensionName,not_dependent)
				DownloadURL:=this.module_DDLLink(DownloadURL)
				UrlDownloadToFile, %DownloadURL%, %downloadlocation%
				this.extension_isCompatible(ExtensionName,downloadlocation)
			}
		}
		this.addDependent("module_extensionmanager", ModuleName "#" ExtensionName)
	}
}