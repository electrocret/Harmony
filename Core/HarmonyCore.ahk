#singleinstance

;Core Includes
#include *i %A_ScriptDir%\core\VariableManager.ahk
#include *i %A_ScriptDir%\core\TriggerManager.ahk
#include *i %A_ScriptDir%\core\Includer.ahk
#include *i %A_ScriptDir%\core\GuiTemplate.ahk
#include *i %A_ScriptDir%\core\GuiHelper.ahk
#include *i %A_ScriptDir%\core\FuncHelper.ahk
#include *i %A_ScriptDir%\core\ExtensionManager.ahk
#include *i %A_ScriptDir%\core\Dependency.ahk
#include *i %A_ScriptDir%\core\Base_Trigger.ahk
#include *i %A_ScriptDir%\core\Array.ahk
#include *i %A_ScriptDir%\core\ActionManager.ahk


Class module_manager extends module_base {
#include *i %A_ScriptDir%\Generated\Extension_manager.ahk
	static Core_version:= 1.0
	static Core_Unique_TempDir:=0
	static Core_sandbox:=0
	static Core_datastore_Builtin:="this,this_module,file,any,all"
	static Core_datastore_builtin_only_namespaces:="extension,module,core,core_directory"
	static Core_Directory_Resources:=A_scriptdir "\Resources"
	static Core_Directory_Include_Resources:=module_manager.Core_Directory_Resources "\Include Resources"
	static Core_Directory_Sounds:=module_manager.Core_Directory_Resources "\Sounds"
	static Core_Directory_Icons:=module_manager.Core_Directory_Resources "\Icons"
	static Core_Directory_Backup:=A_scriptdir "\Backup"
	static Core_Directory_Core:=A_ScriptDir "\Core"
	static Core_Directory_Updates:=module_manager.Core_Directory_Core "\Updates"
	static Core_Directory_Extensions:="\Extensions"
	static Core_LoadMsg_Pre_Loading:="Pre-Initializing..."
	static Core_LoadMsg_Loading:="Initializing..."
	static Core_LoadMsg_Reconfiguring:="Pending Code Reconfiguration..."
	static Core_LoadMsg_Updating:="Checking Updates..."
	static Core_LoadMsg_Cleanup:="Cleaning Up..."
	static Core_LoadMsg_Patching:="Patching..."
	static Core_Module_ConfigModes:="tray,menu"
	static module_datastore_default:="file"
	static module_version:=1.0
	static module_about:="Manager maintains a registry of all modules, and coordinates their startup and configuration. `nCreated by Electrocret"
	static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/HarmonyCore.ahk"
	static module_initialize_level:=1
	static module_configurable_tray:=1
	core_file()	{
		return A_LineFile
	}
	Core_Preinit(){
		static prlocked:=0
		if(module_manager.Core_sandbox)
			return
		if(!prlocked)
		{
			prlocked:=1
			this.notifierlock:=module_guihelper.aggregate() ;Begins Notification Aggregation
			;#### Section sets up Core Directories #####
			{
				; Detemines Temp Directory
				if(!this.Core_Unique_TempDir)	
				{
					Temp:=A_Temp "\Harmony"
					FileRemoveDir, %Temp%,1
				}
				else
					Temp:=A_Temp "\Harmony\" A_ScriptHwnd
				this.datastore_set("Temp","Core_Directory", Temp)
				FileCreateDir, %A_scriptdir%\Generated	;Creates Directory for Generated Files
				this.datastore_set_namespace_Datastore("Core_Directory","this_module") ;Sets where Core Directories are stored
				this.datastore_add_Variable("Core_Directory","Updates","Temp","Backup","Resources","Include_Resources","Icons","Sounds","Extensions") ;Sets what are Core Directories
				;Creates the Actual Directories for Core Directories if they don't exist.
				core_directories:=this.datastore_Variables("Core_Directory")
				loop % core_directories.MaxIndex()
				{
					dir:=this.datastore_get(core_directories[A_Index],"Core_Directory")
					FileCreateDir, %dir%
				}
			}
			this.module_checkinit() ;Initializes Manager/Core
			;##### Section configures Default Values for Core #####
			{
				this.config_add("Modules","Core",this.Core_default_modules())
				this.config_add("LoadScreen","",1)
				this.config_add("Check_Frequency","AutoUpdate",2)
			}
			;##### Section configures Core Variables #####
			{
				this.datastore_Set("Category","module","Core")
				this.datastore_add_Variable("Core","version","Module_ConfigModes","Unique_TempDir") 
				this.datastore_add_Variable("Core_LoadMsg","Loading","Pre_Loading","Reconfiguring","Updating","Cleanup","Patching") ;Core Load Messages
			}
			;##### Section begins Core Pre-Init #####
			this.Core_configmode(1) ;Enter Configmode
			this.Core_LoadScreen("Pre_Loading") ;Puts up Pre-Loading Splash
			module_guihelper.menu_add("tray","module_manager_tray_handler","Configure") ;Reserves Location in Tray Menu
			;### Section Verifies All Modules in Module List still exist in the script ###
			Modules:=this.datastore_Get("Modules","Core")
			Loop % Modules.MaxIndex()		{
				if(this.isModule(Modules[A_Index]))
					this.reg(Modules[A_Index]) ;Loads Module config
				else
					this.unreg(Modules[A_Index]) ;Removes Modules that no longer exist.
			}
			;##### Section Finishes Pre-Init ###
			this.pre_initialized:=1	;Marks Core as Pre-Initialized
			this.module_checkinit()
			this.Core_configmode_check_reload()
			this.Core_func_all_exec("module_checkinit") ;Performs Module Pre-Init
			this.config_save()
			this.Core_configmode_check_reload()
		}
	}
	Core_Init(){
		static locked:=0
		if(module_manager.Core_sandbox)
			Exit
		if(!locked and !this.initialized){
			locked:=1
			this.Core_Preinit() ;Verifies Core has been Pre-Inited
			this.Core_func_all_exec("module_checkinit") ;Ensures that each module has had their config loaded and been pre-inited
			this.Core_LoadScreen() ;Clears Pre-Loading Splash
			this.Core_configmode_check_reload()
			;#### Section Begins Normal Init Process #####
			this.Core_LoadScreen("Loading") ;Puts up Loading Screen
			this.initialized:=1	;Marks module_manager Initialized
			Loop, 100	{
				this.initialize_level:=A_Index
				this.Core_func_all_exec("module_checkinit")
				this.Core_configmode_check_reload()
			}
			this.initialize_level:=-1
			this.Core_LoadScreen()
			;##### Section Begins Post-init/Cleanup Process #####
			this.Core_LoadScreen("Cleanup") ;Puts up  Post-init/Cleanup  Splash
			this.Core_func_all_exec("module_checkinit")
			this.Core_Config_SaveAll()	;Saves all registered Modules Configs
			this.gen_tray_menu() ;Generates Manager Tray Menu
			module_guihelper.aggregate(this.notifierlock) ;Ends Notification Aggregation
			this.hook_hooks(1) ;Tells Hook to begin caching Functions
			this.hook(A_thisFunc) ;Implements any possible hook for Core_init
			this.Core_LoadScreen() ;Clears  Post-init/Cleanup  Splash
			this.Core_configmode(0) ;Exits Config Mode
		}
		Exit
	}
	Core_default_modules(){
	return Array("module_base","module_guihelper","module_funchelper","module_triggermanager","module_actionmanager","module_variablemanager","module_includer","module_extensionmanager","module_dependency","module_base_trigger","module_array","module_guitemplate","module_manager")
	}
	Core_base_modules()	{
		Modules:=this.datastore_Get("Modules","Core",this.Core_default_modules())
		Output:=Array()
		Loop % Modules.MaxIndex()
		{
			if(SubStr(Modules[A_Index],1,11) == "module_base")
				Output.push(Modules[A_Index])
		}
		return Output
	}
	Core_configmode_check_reload()	{
		if(this.Core_configmode(-2).contains("reload"))
		{
			this.Core_Config_SaveAll()
			this.Core_configmode(0)
		}
	}
	Core_configmode(state:=-1){
		static configuremode:=0,datastore_action:=array()
		if(module_manager.Core_sandbox)
			return
		if state is number		
		{
			if(state == -1)
				return configuremode
			else if(state == -2)
				return datastore_action
			else if(state == 1)
				configuremode:=1
			else if(state == 0)
			{
				loop % datastore_action.MaxIndex()
				{
					if(datastore_action[A_Index] != "reload")
						this.Core_configmode(datastore_action[A_Index])
				}
				configuremode:=0
				if(!datastore_action.contains("reload"))
				{
					this.config_remove("cm_count")
					this.config_remove("cm_delay")
					backupdir:=module_manager.datastore_get("Backup","Core_Directory")
					FileRemoveDir, %backupdir%\Configs,1 
					FileCopyDir, %A_scriptdir%\Configs, %backupdir%\Configs
				}
				else
				{
					datastore_action:=array()
					this.Core_configmode("reload")
				}
			}
		}
		else if(isobject(state))		{
			datastore_action:=state
		}
		else if(configuremode and !datastore_action.contains(state))		{
			;caches actions
			StringLower, state, state
			datastore_action.push(state)
			if(this.datastore_get("LoadScreen","",1) and state == "reload" and module_manager.initialize_level != -1)
			{
				this.Core_LoadScreen("Reconfiguring")
				this.Core_LoadScreen("Reconfiguring")
			}
		}
		else if(!configuremode)		{
			;This section performs the originally intended actions
			if(state == "reload")
			{
				cm_count:=this.datastore_get("cm_count","",0)
				cm_delay:=this.datastore_get("cm_delay","",1)
				if(cm_count == cm_delay*10)
				{
					MsgBox , 51, Script Reconfiguration Loop, The script has reconfigured itself %cm_count% times. `n-It is possible that there is a reconfiguration loop. `n-It is also possible that several new Includes or Extensions have been added causing it to reconfigure multiple times, and there are actually no problems.`n`nWould you like to restore the last stable configuration?`n(cancel exits the script)
					ifmsgbox, yes
					{
						backupdir:=module_manager.datastore_get("Backup","Core_Directory")
						FileRemoveDir, %A_scriptdir%\Configs,1 
						FileCopyDir, %backupdir%\Configs, %A_scriptdir%\Configs
					}
					ifmsgbox,cancel
					{
						this.config_remove("cm_count")
						this.config_remove("cm_delay")
						ExitApp
					}
					ifmsgbox, no
					{
						cm_delay++
						this.config_set("cm_delay","",cm_delay)
						cm_count++
						this.config_set("cm_count","",cm_count)
					}
				}
				else
				{
					cm_count++
					this.config_set("cm_count","",cm_count)
				}
				if(this.datastore_get("LoadScreen") and datastore_action.length() == 0 and module_manager.initialize_level != -1)
					this.Core_LoadScreen("Reconfiguring")
				this.Core_Config_SaveAll()
				reload
			}
			else
				this.module_func_exec(state)
		}
	}
	Core_LoadScreen(msgname:="",msg:="",displaydelay:=200,msgpriority:=0)	{
		static turnedon:=0,smsgpriority:=0,msgnamecache:=Array(), msgcache:=Array(),prioritycache:=array()
		if(!this.Core_configmode(-1))
		{
			Progress, off
			return
		}
		if(this.datastore_get("LoadScreen","",1) or turnedon)
		{
			if(msgname == "")
			{
				if(displaydelay == -1)
				{
					if(isobject(msgpriority))
						msgnamecache:=msgpriority
					return msgnamecache
				}
				if(msgnamecache.length() <= 1 or msgpriority == -1)
				{
					msgnamecache:=Array()
					prioritycache:=array()
					msgcache:=Array()
					turnedon:=0
					smsgpriority:=0
					Progress, off
				}
				else
				{
					prioritycache.pop()
					msgnamecache.pop()
					msgcache.pop()
					smsgpriority:=prioritycache.pop()
					msgname:=msgnamecache.pop()
					msg:=msgcache.pop()
					this.Core_LoadScreen(msgname,msg,200,smsgpriority)
				}
			}	
			else if(smsgpriority <= msgpriority)
			{
				smsgpriority:=msgpriority
				turnedon:=1
				if(this.isModule(msg))
					msg:=this.Core_format_module_Readable(msg)
				msgnamecache.push(msgname)
				prioritycache.push(msgpriority)
				msgcache.push(msg)
				cm_count:=this.datastore_get("cm_count","",0)+1
				if(cm_count > 1)
					cm_count:="x" cm_count
					else
					cm_count:=""
				canmsg:=module_manager.datastore_get(msgname,"Core_LoadMsg") 
				if(msg == "")
				{
					if(canmsg == "")
						return
					displaymsg:=canmsg
				}
				else
				{
					if(canmsg == "")
						displaymsg:=msg
						else
						displaymsg:= msg " - " canmsg
				}
				Progress, m2 b fs13 zh0 WMn700,%displaymsg% %cm_count%
				if displaydelay is number
					sleep %displaydelay%
				else
					sleep 200
			}
		}
		return smsgpriority
	}
	Core_func_all_exec(Function,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±",byref Var10:="±")	{
		this.module_checkinit()
		Modules:=this.datastore_Get("Modules","Core",this.Core_default_modules())
		Loop % Modules.MaxIndex()
			this.module_func_exec(Modules[A_Index] "." Function,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
	}
	Core_format_module_Readable(Module)	{
		if(this.isModule(Module))
		{
			if(isobject(Module))
				return Format("{:T}",SubStr(Module.__Class,8))
				else
				return Format("{:T}",SubStr(Module,8))
		}
	}
	Core_format_module_natural(PartialName)	{
		if(this.isModule(PartialName))
		{
			if(isobject(PartialName))
				PartialName:= PartialName.__Class
			stringlower, PartialName,PartialName
			return PartialName
		}
		stringlower, PartialName,PartialName
		if(this.hook(A_thisFunc,PartialName))
			return  this.hook_value(A_thisFunc)
		TestName:="module_" PartialName
		if(this.isModule(TestName))
			return TestName
	}
	Core_Config_SaveAll(){
	this.Core_func_all_exec("Config_Save")
	}
	Core_datastore_all_add_Variable(namespace, VariableNames*)	{
		all_variables:=this.datastore_get("Variables","Core",Array())
		if(namespace == "")
		{
			for index,VariableName in VariableNames
			{
				module:=this.Core_format_module_natural(Variablename)
				if(module != "")
				{
					For ns, val in all_variables
					this.module_func_mod_exec(module,"module_base.datastore_add_Variable",ns,val)
					moduleprovided:=1
				}
			}
			if(!moduleprovided)
				For ns, val in all_variables
					this.Core_func_all_exec("datastore_add_Variable",ns,val)
			return
		}
		nsvariables:=all_variables[namespace]==""?Array():all_variables[namespace]
		for index,VariableName in VariableNames
			if(!nsvariables.contain(VariableName))
			{
				nsvariables.push(VariableName)
				added:=1
			}
		all_variables[namespace]:=nsvariables
		this.datastore_set("Variables","Core",all_variables)
		if(added)
		 this.Core_datastore_all_add_Variable("","")
	}
	reg(Modules*)	{
		output:=0
		regen_tray:=0
		this.module_checkinit()
		for index,Module in Modules
		{
			if(isobject(Module))
			{
				if(Module.__Class == "" or Module.__Class == "_Array")
				{
					Loop % Module.MaxIndex()
						output:=this.reg(Module[A_Index]) or output ? 1 :0
				}
				else
					output:=this.reg(Module.__Class) or output ? 1:0
			}
			else
			{
				module:=this.Core_format_module_natural(module)
				Modules:=this.datastore_Get("Modules","Core",this.Core_default_modules())
				if(this.isModule(Module))
				{
					output:=1
					module_dependency.beginDependentBuild("module_manager",Module)
					this.module_func_exec( Module ".module_checkinit")
					module_dependency.endDependentBuild()
					if(!Modules.contains(Module))
					{
						module_includer.check_includer("module_manager",Module)
						this.Core_datastore_all_add_Variable("",Module)
						Modules.push(Module)
						this.config_set("Modules","Core",Modules)
						this.hook_hooks(-1)
					}
					
					if(this.isModule_Configurable(module,"tray"))
						regen_tray:=1
				}
				else if(Modules.contains(Module))
					this.unreg(Module)
			}
		}
		if(regen_tray)
			this.gen_tray_menu()
		return output
	}
	unreg(Modules*){
			regen_tray:=0
			for index,Module in Modules
			{
				if(this.hook(A_thisFunc,Module))
					continue
				if(isobject(Module))
				{
					if(Module.__Class == "" or Module.__Class == "_Array")
					{
						Loop % Module.MaxIndex()
							this.unreg(Module[A_Index])
					}
					else
						this.unreg(Module.__Class)
				}
				else if(module_dependency.removeDependent("module_manager",Module))
				{
					Modules:=this.datastore_Get("Modules","Core",this.Core_default_modules())
					if(modules.contains(Module))
					{
						modules.removeAt(modules.indexof(Module))
						this.hook_hooks(-1)
						this.config_set("Modules","Core",Modules)
						if(%Module%.datastore_Get("Unreg_Reload","module",0))
							this.Core_configmode("reload")
					}
					if(this.isModule_Configurable(module,"tray"))
						regen_tray:=1
				}
			}
			if(regen_tray)
				this.gen_tray_menu()
	}
	isModule(Module){
		if(!isobject(Module))
		{
			try
			{
				if(isobject(%Module%))
					return SubStr(Format("{:L}",Module), 1, 7) == "module_"
				return 0
			}
			catch e
				return 0
		}
		return SubStr(Format("{:L}",Module.__Class), 1, 7) == "module_"
	}
	isModule_Configurable(Module,confmode:=""){
		if(isobject(Module))
			Module:=module.__Class
		else
			module:=this.Core_format_module_natural(Module)
		if(confmode == "")
			confmode:=module_manager.cache_get("Module_ConfigModes","Core")
		output:=0
		if(isfunc(module ".module_configure"))
		{
			if(%module%.datastore_get("Configurable","Module",1))
				return 1
			else
			{
				if(InStr(confmode,","))
				{
					Loop, Parse, confmode,`,
					{
						if(%module%.datastore_get("Configurable_" A_Loopfield,"Module",0))
							return 1
					}
				}
				else if(%module%.datastore_get("Configurable_" confmode,"Module",0))
					return 1
			}
		}
		return 0
	}
	isReg(Module,Type:="")	{
		Module:=this.Core_format_module_natural(Module)
		StringLower, Module, Module
		return this.datastore_Get(Type "Modules","Core",Array()).contains(Module)
	}
	Version(module:="",extension:="")	{
		module:=module_manager.Core_format_module_natural(module)
		if(module == "")
			return this.datastore_get("Version","Core")
		if(extension == "")
			return %module%.datastore_get("Version","module")
		return %module%.datastore_get(Format("{:L}",extension) "_Version","extension_info")
	}
	gen_tray_menu()	{
		if(module_manager.initialized and module_manager.initialize_level == -1)
		{
			module_guihelper.menu_deleteAll("tray","module_manager_tray_handler")
			Modules:=this.datastore_Get("Modules","Core")
			Loop % Modules.MaxIndex()
			{
				module:=modules[A_Index]
				if(this.isModule_Configurable(module,"tray"))
					module_guihelper.menu_add("tray","module_manager_tray_handler","Configure." %Module%.datastore_get("Category","module","") "." this.Core_format_module_Readable(Module))
			}
		}		
	}
	module_dependency(Directive,DependentName){
		if(Directive == "remove")
			return module_manager.unreg(DependentName)
		return module_manager.reg(DependentName)
	}
	module_info(Module)	{
		if(this.hook(A_thisFunc,Module))
			return  this.hook_value(A_thisFunc)
		if(isobject(Module))
		{
			modulename:=module.modulename
			if(module.guiaction == "Button1" and module.vDropdownlist1 != "")
			{
				%modulename%.extension_about(module.vDropdownlist1) ;Extension About
			}
			if(module.GUIAction == "Button2")
			{
				if(!this.datastore_get(modulename,"AutoUpdate",1))
				{
					msgbox,36, Auto Update %modulename%, Auto Updates for %modulename% are currently disabled.`nwould you like to enable it?
					ifmsgbox, yes
						this.config_remove(modulename,"AutoUpdate")
				}
				%modulename%.module_update()	;Checks for updates
				extensions:=%modulename%.datastore_get("Extensions","extension",Array())
				if(extensions.length() > 0)
				{
					msgbox,36, Update %modulename% Extensions, Do you want to check for updates for %modulename%'s extensions?
					ifmsgbox, yes
					{
						Loop % extensions.MaxIndex()
						{
							extensionident:=%modulename%.extension_update_ident(extensions[A_Index])
							if(!this.datastore_get("Extension_" extensionident,"AutoUpdate",1))
							{
								msgbox,36, Auto Update %extensionident%, Auto Updates for %extensionident% are currently disabled.`nwould you like to enable it?
								ifmsgbox, yes
									this.config_remove("Extension_" extensionident,"AutoUpdate")
							}
							%modulename%.extension_update(extensions[A_Index])
						}
					}			
				}
			
			}
			if(module.GUIAction == "Button3" or module.GUIAction == "GuiClose")
			{
				this.module_configure()
				return
			}
		}
		else
		{
			Module:=this.Core_format_module_natural(module)
			if(!this.isModule(module))
			{
				this.module_configure()
			}
			version:=%Module%.datastore_get("Version","module","")
			display_name:=version == ""? this.Core_format_module_Readable(module): this.Core_format_module_Readable(module) " v" version
			abouttext:=%Module%.datastore_get("About","module","")
			this.about_notfound(abouttext,display_name," If you are the Module programmer, I'd suggest creating a static variable in this module's class named 'module_about', and take some credit for your hard work.")
			extensions:=%module%.datastore_get("Extensions","extension",Array())
			Loop % extensions.MaxIndex()
				extensionlist.="|" Format("{:T}",extensions[A_Index])
			module:={Edit1:abouttext,Dropdownlist1:extensionlist,Groupbox1:"About " display_name,modulename: module}
		}
		module_guitemplate.about(A_thisFunc,module)
	}
	about_notfound(byref abouttext,display_name,fixissue_suggestion)	{
		if(abouttext == "")
		{
			Random, noabout , 1, 2
			if(noabout == 1)
				abouttext:= display_name " just wants to be loved. Will you love me?"
			else if(noabout == 2)
				abouttext:="The programmer of " display_name " hated it so much they didn't want to put their name on it, or anything. hopefully it doesn't blow up your computer!!!"
			abouttext.="`n`nJoking aside -" fixissue_suggestion
		}
	}
	module_init(){
			this.Core_Preinit()
	}
	module_configure(module:=""){
		if(this.hook(A_thisFunc,module))
			return  this.hook_value(A_thisFunc)
		this.Core_configmode(1)
		if(isobject(module))
		{
			if(module.secondary == 1)
			{
				if(module.GUIAction == "Button1")
				{
					InputBox, newmodule , New Module, Enter New Module name:
					this.reg(this.Core_format_module_natural(newmodule))
				}
				if(module.GUIAction == "Button2" and module.vListbox1 != "")
				{
					selected:=module.vListbox1
					MsgBox, 4, Remove Module, Are you sure you want to remove %selected%?
					ifmsgbox, yes
						this.unreg(this.Core_format_module_natural(selected))
				}
				if(module.GuiAction == "Button3" and module.vListbox1 != "")
				{
					this.module_info(this.Core_format_module_natural(module.vListbox1))
					return
				}
				if(module.GUIAction == "Button4" or module.GUIAction == "GuiClose")
				{
					this.module_configure()
					return
				}
				Modules:=this.datastore_Get("Modules","Core")
				Loop % Modules.MaxIndex()
						modlist.="|" this.Core_format_module_Readable(Modules[A_Index])
				module.Listbox1:=modlist
				module_guitemplate.Manager(A_thisFunc,module)
				return
			}
			if(module.GUIAction == "Button1")
			{
				Modules:=this.datastore_Get("Modules","Core")
				Loop % Modules.MaxIndex()
					modlist.="|" this.Core_format_module_Readable(Modules[A_Index])
				GInfo:={Windowtitle: "Manage Modules", groupbox1: "Modules", Button1: "Add Module",Button2: "Remove Module",Button3: "Module Info", Button4: "Done",Listbox1: modlist ,secondary: 1}
				module_guitemplate.Manager(A_thisFunc,GInfo)
			}
			selectedmod:=module.vDropdownlist1
			if(module.GUIAction == "Button2" and selectedmod != "")
			{
				module:=this.Core_format_module_natural(selectedmod)
				%module%.module_configure()
				return
			}
			if(module.GUIAction == "Button3" or module.GUIAction == "GuiClose")
			{
				this.Core_Config_SaveAll()
				this.Core_configmode(0)
				return
			}
		}
		else if(this.isModule_Configurable(module))
		{
				module:=this.Core_format_module_natural(module)
				%module%.module_configure()
				return
		}
		Modules:=this.datastore_Get("Modules","Core",Array())
		Loop % Modules.MaxIndex()
		{
			if(Modules[A_Index] != this.__Class and module_manager.isModule_Configurable(Modules[A_Index],"menu"))
				confmodlist.="|" this.Core_format_module_Readable(Modules[A_Index])
		}
		GInfo:={Windowtitle: "Configure Modules", groupbox1: "Configurable Modules", Button1: "Manage Modules",Button2: "Configure Module",Button3: "Done",Dropdownlist1: confmodlist}
		module_guitemplate.ThreeButtonDropdown(A_thisFunc,GInfo)
		this.Core_Config_SaveAll()
		return
	}
}

module_manager_tray_handler(ItemName, ItemPos, MenuName){
	module_manager.module_configure(ItemName)
}


;############################################## MODULE BASE ##############################################
;############################################## MODULE BASE ##############################################

Class module_base {
	#include *i %A_ScriptDir%\Generated\Extension_base.ahk
	static module_base_module_about:="Base is the base of all module classes. `nCreated by Electrocret"
	static module_base_module_version:=1.0
	;Checks if this class has already been initialized. if it hasn't, and is enabled then it initializes class
	core_file()	{
		return A_LineFile
	}
	module_checkinit(runinit:=1,initlvl:=-1)	{
		static init:=Array(),locks:=Array()
		if((init[ this.__Class] < 4 or init[ this.__Class] == "" or init[ this.__Class] is not number) and runinit and !locks[ this.__Class])	{
			locks[ this.__Class]:=1 ;Locks checkinit for this module
			if(init[ this.__Class] == "" or init[ this.__Class] is not number)
			{
				;Module Config Load and Register
				init[ this.__Class]:=initlvl != -1? initlvl:0
				module_manager.core_preinit()
				this.datastore_set_Default_Datastore(this.datastore_get("datastore_default","module","","any"))
				this.datastore_set("Registered","module",module_manager.reg(this))
				this.datastore_set("PreInitialized","module",0)
				this.datastore_set("AutoUpdated","module",0)
				this.datastore_set("Initialized","module",0)
				this.datastore_set("PostInitialized","module",0)
				this.datastore_set_namespace_Datastore("extension_info","file")
				this.datastore_set_namespace_Datastore("extension","this_module")
				this.datastore_add_Variable("module","About","Registered","PreInitialized","AutoUpdated","Initialized","PostInitialize","initialize_level","Category","Config_File","Version","Unreg_Reload","UpdateURL","ChangeLog","datastore_Default")
				this.config_load()
				
			}
			if(init[ this.__Class] < 1 and module_manager.pre_initialized)	{
				init[ this.__Class]:=initlvl != -1? initlvl:1
				;Core Pre-Init
				if(!this.datastore_get("PreInitialized","module",0))
				{
					this.datastore_set("PreInitialized","module",1)
					this.module_preinit()
					this.hook("module_preinit")
					if(!this.datastore_get("PreInitialized","module",1))
						init[ this.__Class]:=initlvl != -1? initlvl:0
				}
			}
			if(init[this.__Class] < 2 and module_manager.pre_initialized)	{
				init[ this.__Class]:=initlvl != -1? initlvl:2
				;Check for Updates
				if(!this.datastore_get("AutoUpdated","module",0))
				{
					this.datastore_set("AutoUpdated","module",1)
					patchversion:=this.datastore_get("patch","module","")
					if(patchversion != "")
					{
						this.config_remove("patch","module")
						this.module_patch(patchversion)
						this.config_save()
						module_manager.Core_configmode_check_reload()
					}
					extensions_to_patch:=this.datastore_get("Patch","extension","")
					if(extensions_to_patch != "")
					{
						this.config_remove("Patch","extension")
						Loop % extensions_to_patch.MaxIndex()
						{
							lastversion:=this.datastore_get(extensions_to_patch[A_Index] "_Patch","extension")
							this.config_remove(extensions_to_patch[A_Index] "_Patch","extension")
							this.hook_single("extension_patch",extensions_to_patch[A_Index],lastversion)
						}
						this.config_save()
						module_manager.Core_configmode_check_reload()
					}
					this.module_update(1)
					this.extension_update("",1)
					if(!this.datastore_get("AutoUpdated","module",1))
						init[ this.__Class]:=initlvl != -1? initlvl:1
				}
			}
			if(init[ this.__Class] < 3 and module_manager.initialized == 1)	{
				;Core Init
				initialize_level:=this.datastore_get("initialize_level","module",50)
				if(((module_manager.initialize_level >= initialize_level and initialize_level != -1) or module_manager.initialize_level == -1))	{
					init[ this.__Class]:=initlvl != -1? initlvl:3
					if(!this.datastore_get("Initialized","module",0))
					{
						this.datastore_set("Initialized","module",1)
						if(module_manager.initialize_level != -1)
							module_manager.Core_LoadScreen("loading",this)
						module_dependency.beginDependentBuild("module_manager",this.__Class)
						this.module_init()
						this.hook("module_init")
						module_dependency.endDependentBuild()
						this.config_Save()
						if(module_manager.initialize_level != -1)
							module_manager.Core_LoadScreen()
						if(!this.datastore_get("Initialized","module",1))
							init[ this.__Class]:=initlvl != -1? initlvl:2
					}
				}
			}
			if(init[this.__Class] < 4 and module_manager.initialized == 1 and module_manager.initialize_level == -1) {
				init[ this.__Class]:=initlvl != -1? initlvl:4
				;Core Post-init - Cleanup
				if(!this.datastore_get("PostInitialized","module",0))
				{
					this.datastore_set("PostInitialized","module",1)
					this.module_postinit()
					this.hook("module_postinit")
					if(!this.datastore_get("PostInitialized","module",1))
						init[ this.__Class]:=initlvl != -1? initlvl:3
					this.Config_set_ConfigHelper_Datastore("file")
					this.datastore_set_namespace_Datastore("module","file")
					this.datastore_add_Variable("module","Configurable")
					confmode:=module_manager.datastore_get("Module_ConfigModes","Core")
					Loop, Parse, confmode,`,
						this.datastore_add_Variable("module","Configurable_" A_Loopfield)
				}
			}
			locks[ this.__Class]:="" ;Unlocks checkinit for this module
		}
		else if(runinit == 0 and initlvl != -1)
			init[ this.__Class]:=initlvl
		return init[ this.__Class]
	}
	module_update(autoupdate:=0){
		if((!module_manager.datastore_get(module_manager.Core_format_module_Readable(this.__Class),"AutoUpdate",1) or this.datastore_get("UpdateURL","module") == "") and autoupdate == 1)
			return 0
		UpdateFile:=this.module_update_file(autoupdate== 0 or autoupdate == -1)
		ifExist, %UpdateFile%
		{
			if(autoupdate == 1)
			{
				FormatTime, CurrentCheck,, YDay
				FileGetTime, fLastCheck, %UpdateFile%
				FormatTime,LastCheck,fLastCheck,YDay
				CheckLapse:=LastCheck-CurrentCheck
				if(CheckLapse > module_manager.datastore_get("Check_Frequency","AutoUpdate",2))
					return this.module_update(-1)
				return 0
			}
			currentversion:=this.datastore_get("version","module",0)
			newversion:=this.module_update_extract("version","module",currentversion)
			if(currentversion < newversion)
			{
				changelog:=this.module_update_extract("ChangeLog","module","No ChangeLog Entry Found")
				title:="Update for Module " frmodname
				msg:="New Version of " frmodname " available!`nCurrent Version: " currentversion "`nNew Version: " newversion "`nChangeLog:`n" changelog "`n`nDo you want to apply the update?`n(A Backup will be created)"
				if(autoupdate == -1)
					msgbox, 67, %title%, %msg%`n(Cancel Disables AutoUpdates)
					else
					msgbox, 68, %title%, %msg%
				ifmsgbox, yes
				{
					scriptfile:=module_includer.getIncludedFile("module_manager",this.__Class,1)
					SplitPath, scriptfile , BackupFilename
					BackupFilename:=currentversion "_" BackupFilename
					backupdir:=module_manager.datastore_get("Backup","Core_Directory")
					info:=module_includer.getIncludedDependency("module_manager",this.__Class)
					if(info != "")
						backupdir:=backupdir "\" info.include_type "s"
					else if(isfunc(this.__Class ".core_file"))
						backupdir:=backupdir "\core"
					FileCreateDir, %backupdir%
					FileCopy, %scriptfile%, %backupdir%\%BackupFilename%,1 ;Copies file to backup directory
					FileCopy, %UpdateFile%, %scriptfile%,1
					this.config_set("Patch","module",currentversion)
					module_manager.Core_configmode("reload")
					return 1
				}
				ifmsgbox, cancel
				{
					module_manager.config_remove(frmodname,"AutoUpdate_LastCheck")
					module_manager.config_set(frmodname,"AutoUpdate",0)
				}
			}
		}
		return 0
	}
	module_scriptfile_syntax(Filename,displayerror:=0)	{
		;Codes: -1=Unknown error, 0=File does not exist, 1=Unknown Action, 2=Duplicate class, 3=Duplicate Function, 4= Duplicate Declaration, 5= Duplicate Labels, 6= Function cannot contain functions,
		ifExist, %Filename%		
		{
			cachedir:=module_manager.datastore_get("Temp","Core_Directory")
			batchfile:="echo Testing for Syntax errors " Filename "`n"""A_AhkPath """  /ErrorStdOut """ Filename """ 2>""" cachedir "\SyntaxError.txt"""
			FileAppend, %batchfile%,%cachedir%\syntax_check.bat
			RunWait, %cachedir%\syntax_check.bat
			FileDelete, %cachedir%\syntax_check.bat
			FileRead, fullerror, %cachedir%\SyntaxError.txt
			FileDelete, %cachedir%\SyntaxError.txt
			if(fullerror == "")
				return
			ferror:=Array()
			shortenederror:=substr(fullerror,InStr(fullerror," (")+2)
			ferror.lineerror:="Line: " substr(shortenederror,1,InStr(shortenederror,")")-1), ferror.errortype:=substr(shortenederror,InStr(shortenederror,"==> ")+4,inStr(shortenederror,"`n")-(InStr(shortenederror,"==> ")+5)),	ferror.errorspecific:=substr(shortenederror,InStr(shortenederror,"Specifically: ")+14,inStr(shortenederror,"`n",false,InStr(shortenederror,"Specifically: "))-(InStr(shortenederror,"Specifically: ")+15)),	ferror.fullerror:=fullerror, ferror.shortenederror:=shortenederror
			ferror.code:=ferror.errortype == "This line does not contain a recognized action." ? 1: ferror.errortype == "Duplicate class definition."?2: ferror.errortype == "Duplicate function definition."?3:ferror.errortype == "Duplicate declaration." ? 4 : ferror.errortype == "Duplicate label."? 5: ferror.errortype == "Functions cannot contain functions."? 6 : -1
			if(displayerror)
				msgbox %fullerror%
			return ferror
		}
		return {code:0,errortype:"File does not exist", errorspecific: Filename}
	}
	module_scriptfile_comment(Filename,VariableName)	{
		FileRead, filecontents, %Filename%
		filecontents.=" `r" A_Tab
		StringLower, lowerfilecontents,filecontents
		search:=";" Format("{:L}",VariableName) ":="
		StringGetPos,startpos,lowerfilecontents,%search%
		if(!ErrorLevel)
		{	
			startpos:=startpos+StrLen(search)+1
			StringGetPos,spacepos,lowerfilecontents,%A_Space%,,%startpos%
			StringGetPos,tabpos,lowerfilecontents,%A_Tab%,,%startpos%
			StringGetPos,returnpos,lowerfilecontents,`r,,%startpos%
			endpos:=spacepos < tabpos and spacepos < returnpos? spacepos : returnpos < tabpos ?returnpos:tabpos
			endpos++
			length:=endpos-startpos
			output:=substr(filecontents,startpos,length)
		}
		return output
	}
	module_scriptfile_module_var(Filename,ModuleName,Variable,namespace,defaultvalue:="")	{
		if(module_manager.Core_sandbox)
			return defaultvalue
		if(isobject(ModuleName))
			ModuleName:=ModuleName.__Class
		if(!FileExist(Filename))
		{
			Filename:=module_includer.getIncludedFile("module_manager",ModuleName)
			if(!FileExist(Filename))
				return defaultvalue
		}
		outputfile:=module_manager.datastore_get("Temp","Core_Directory") "\sandbox_module_var.txt"
		testfilecontent.=ModuleName ".module_init()`nvalue:=module_base.module_format_toString(" ModuleName ".datastore_get(""" variable """,""" namespace ""","""",""any""))`nFileAppend , %value%, " outputfile
		normalmodulefile:=module_includer.getIncludedFile("module_manager",ModuleName)
		baseincludes:=module_manager.Core_base_modules()
		Loop % baseincludes.MaxIndex()
		{
			baseincludefile:=module_includer.getIncludedFile("module_manager",baseincludes[A_Index])
			if(baseincludefile != normalmodulefile)
				testfilecontent.="#Include *i " baseincludefile "`n"
		}
		this.module_scriptfile_sandbox(Filename,testfilecontent)
		FileRead, output, %outputfile%
		filedelete %outputfile%
		return output==""?defaultvalue:output
	}
	module_scriptfile_var(Filename,Variable,DefaultValue:=""){
		if(!module_manager.Core_sandbox)
		{
			outputfile:=module_manager.datastore_get("Temp","Core_Directory") "\sandbox_var.txt"
			this.module_scriptfile_sandbox(Filename,"value:=" Variable "`nFileAppend , %value%, " outputfile)
			FileRead, output, %outputfile%
			FileDelete, %outputfile%
		}
		return output==""?defaultvalue:output
	}
	module_scriptfile_sandbox(Filename,sandbox_testscript)	{
		if(module_manager.Core_sandbox)
			return
		cachedir:=module_manager.datastore_get("Temp","Core_Directory")
		sandboxtestfile:=cachedir "\sandbox_testfile.ahk"
		sandboxfile:=cachedir "\sandbox.ahk"
		FileCopy %Filename%,%sandboxtestfile%,1
		sandbox_testscript:="#Include *i " sandboxtestfile "`nmodule_Manager.Core_sandbox:=1`n" sandbox_testscript "`nExitApp"
		fileappend %sandbox_testscript%, %sandboxfile%
		out:=this.module_scriptfile_syntax(sandboxfile)
		filedelete %sandboxfile%
		filedelete %sandboxtestfile%
		return out
	}
	module_update_extract(variable,namespace,defaultvalue:="")	{
		if(module_manager.Core_sandbox)
			return defaultvalue
		UpdateFile:=this.module_update_file()
		ifExist, %UpdateFile%
			return this.module_scriptfile_module_var(UpdateFile,this,Variable,Namespace, defaultvalue)
		return defaultvalue
	}
	module_update_file(clear:=0)	{
		updatefile:= module_manager.datastore_get("Updates","Core_Directory") "\" this.__Class ".ahk"
		UpdateURL:=this.module_DDLLink(this.datastore_get("UpdateURL","module")) ;Gets File Download URL
		if(clear and FileExist(updatefile))
			FileDelete %updatefile%
		IfNotExist, %updatefile%
		{
			if(UpdateURL != "")
			{
				module_manager.Core_LoadScreen("updating",this)
				UrlDownloadToFile, %UpdateURL%, %UpdateFile%
				this.module_isCompatible(this.__Class,UpdateFile)
				module_manager.Core_LoadScreen()
			}
		}
		return updatefile
	}
	module_isCompatible(ModuleName:="",Filename:="")	{
		Modulename:=ModuleName==""?this.__Class:module_manager.Core_format_module_natural(ModuleName)
		Filename:=FileExist(Filename)?Filename:module_includer.getIncludedFile("module_manager",Modulename)
		if(!FileExist(Filename))
			return 0
		if(!isobject(this.module_scriptfile_syntax(Filename)))
			return 0
		FileRead, filecontent, %Filename%
		Stringlower, filecontent,filecontent
		if(!InStr(filecontent, "class " Format("{:L}",this.__Class)))
		{
			FileDelete %updatefile%
			return 0
		}
		return 1
	}
	module_DDLLink(URL){
		;GoogleDrive
		ifinstring URL, https://drive.google.com/file/d/		
		{
			StringReplace, URL,URL, https://drive.google.com/file/d/, https://drive.google.com/uc?export=download&id=
			endpos:=instr(URL,"/",false,48)
			endpos--
			URL:=substr(URL,1,endpos)
		}
		;Dropbox
		ifinstring URL, https://www.dropbox.com		
		{
			StringReplace, URL, URL, https://www.dropbox.com, https://dl.dropboxusercontent.com
		}
		;Copy.com
		ifinstring URL, https://www.copy.com/s/		
		{
			StringReplace, URL, URL, https://www.copy.com/s/, https://www.copy.com/
		}
		;Github
		ifinstring URL, https://github.com/		
		{
			startpos:=instr(URL,"/",false,1,5)
			length:=instr(URL,"/",false,1,6)-startpos
			replace:=substr(URL,startpos,length)
			StringReplace, URL,URL,%replace%,/raw
		}
		return URL
	}
	module_eventinfo(event_name, directive:="Execute", event_data:="",additional_values:=""){
		if(this.module_isEventInfo(event_data))
			event_info:=event_data
			else
			event_info:={event_module: this,event_data: event_data}
		event_info.directive:=directive,	event_info.event_name:=event_name
		if(isobject(additional_values))
			For key, val in additional_values
				event_info[key]:=val
		return event_info
	}
	module_eventinfo_setDirective(byref Eventinfo, NewDirective)	{
		if(this.module_isEventInfo(Eventinfo))
		{
			Eventinfo.directive_previous:=Eventinfo.directive
			Eventinfo.directive:=NewDirective
			return 1
		}
		return 0
	}
	module_eventinfo_revertDirective(byref Eventinfo)	{
		if(Eventinfo.directive_previous != "")
		{
			Eventinfo.directive:=Eventinfo.directive_previous
			Eventinfo.directive_previous:=""
			return 1
		}
		return 0
	}
	module_isEventInfo(Eventinfo)	{
		if(isobject(Eventinfo))
			return Eventinfo.event_name != "" and Eventinfo.directive != "" and isobject(Eventinfo.event_module)
		return 0
	}
	module_format_naturalize(value,varsize:=230,sformat:="",repeats:=0){
		if(isobject(value))
			value:=this.module_format_toString(value)
		if(sformat != "")
			value:=format(sformat,value)
		thirds0:=0,	thirds1:=0,	thirds2:=0,	halfs0:=0,	halfs1:=0, thirdsincrement:=0
		Loop, parse, value
		{
			ihalfs:=mod(A_Index ,2)
			thirdsincrement+=ihalfs
			ithirds:=mod(thirdsincrement,3)
			thirds%ithirds%+=Asc(A_loopfield),	halfs%ihalfs%+=Asc(A_loopfield)
		}
		natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
		if(strlen(natural) > varsize)
		{
			halfs0:=this.module_format_naturalize_shrink(halfs0)
			natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
			if(strlen(natural) > varsize)
			{
				halfs1:=this.module_format_naturalize_shrink(halfs1)
				natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
				if(strlen(natural) > varsize)
				{
					thirds0:=this.module_format_naturalize_shrink(thirds0)
					natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
					if(strlen(natural) > varsize)
					{
						thirds1:=this.module_format_naturalize_shrink(thirds1)
						natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
						if(strlen(natural) > varsize)
						{
							thirds2:=this.module_format_naturalize_shrink(thirds2)
							natural:="n" repeats "a" thirds0 "t" halfs0 "u" thirds1 "r" halfs1 "a" thirds2 "l" StrLen(value)
							if(strlen(natural) > varsize and varsize > 0 and repeats < 99)
								natural:=this.module_format_naturalize(natural,varsize,"",repeats++)
						}
					}
				}
			}
		}
		return natural 
	}
	module_format_naturalize_shrink(value){
		if value is number
		{
			output:=""
			while(value > 0)
			{
				modulos:=mod(value,36)
				output.=modulos == 0 ? "0": modulos == 1 ? "1" : modulos == 2 ? "2" : modulos == 3 ? "3" : modulos == 4 ? "4" : modulos == 5 ? "5" : modulos == 6 ? "6" : modulos == 7 ? "7" : modulos == 8 ? "8" : modulos == 9 ? "9" : modulos == 10 ? "Q" : modulos == 11 ? "W" : modulos == 12 ? "E" : modulos == 13 ? "R" : modulos == 14 ? "T" : modulos == 15 ? "Y" : modulos == 16 ? "U" : modulos == 17 ? "I" : modulos == 18 ? "O" : modulos == 19 ? "P" : modulos == 20 ? "A": modulos == 21 ? "S" : modulos == 22 ? "D" : modulos == 23 ? "F" : modulos == 24 ? "G" : modulos == 25 ? "H" : modulos == 26 ? "J" : modulos == 27 ? "K" : modulos == 28 ? "L" : modulos == 29 ? "Z" : modulos == 30 ? "X": modulos == 31 ? "C" : modulos == 32 ? "V" : modulos == 33 ? "B" : modulos == 34 ? "N" : modulos == 35 ? "M" : "#"
				value //= 36
			}
			return output
		}
		return value
	}
	module_format_toString(value){
		if(isobject(value))
		{
			if(value.__Class == "" or value.__Class == "_Array")
			{	
				if value.MaxIndex() is number
				{
					output:="A("
					if(value.length() !=0)
					{
						Loop % value.MaxIndex()
							output.=this.module_format_toString(value[A_Index])"»"
						stringtrimright, output,output,1
					}
					output.=")"
					return output
				}
				else
				{
					output:="R("
					empty:=1
					For key, val in value
					{
						empty:=0
						output.=key ":" this.module_format_toString(val) "«"
					}
					if(!empty)
						stringtrimright, output,output,1
					output.=")"
					return output
				}
			}
			else
			{
				class:=value.__Class
				Msgbox, ERROR: Cannot convert a Class into a string. Only Arrays - %class%
			}
		}
		else
		{
			stringreplace, value, value, `r, µ,All
			stringreplace, value, value, `n, ¶,All
			return value
		}
	}
	module_format_toArray(line){
		line=%line%
		StringGetPos, arraytest, line, A(
		if(Errorlevel == 0 and arraytest == 0)
		{
			stringtrimleft,line,line,2
			stringtrimright, line,line,1
			output:=array()
			loop,parse,line,»
				output.push(this.module_format_toArray(A_Loopfield))
			return output
		}
		else
		{
			Errorlevel:=0
			StringGetPos, assocarraytest, line, R(
			if(Errorlevel == 0 and assocarraytest == 0)
			{
				stringtrimleft,line,line,2
				Stringtrimright,line,line,1
				output:=Array()
				loop,parse,line,«
				{
					StringgetPos, pos,A_Loopfield,:
					key:=SubStr(A_Loopfield,1,pos)
					pos:=pos+2
					value:=this.module_format_toArray(SubStr(A_Loopfield,pos))
					output[key]:=value
				}
				return output
			}
			stringreplace, line, line, µ,`r, All
			stringreplace, line,line, ¶, `n, All
			return line
		}
	}
	module_func_exec(Function,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±",byref Var10:="±"){
		IfInString, Function, .
		{
			StringgetPos, pos,function,.
			module:=SubStr(function,1,pos)
			if(!isfunc(Function))
			{
				pos:=pos+2
				afunction:=SubStr(function,pos)
				bmodule:=%module%
				while(bmodule.__Class != "")
				{
					if(isfunc(bmodule.__Class "." afunction))
					{
						Function:=bmodule.__Class "." afunction
						break
					}
					else
						bmodule:=bmodule.base
				}
			}
		}
		return this.module_func_mod_exec(module,Function,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
	}
	module_func_mod_exec(module,Function,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±",byref Var10:="±")	{
		IfInString, Function, .
		{
			if(module != "" and !isobject(module))
				module:=%module%
			if(Var1 == "±")
				return %Function%(module)
			else if(Var2 == "±")
				return %Function%(module,Var1)
			else if(Var3 == "±")
				return %Function%(module,Var1,Var2)
			else if(Var4 == "±")
				return %Function%(module,Var1,Var2,Var3)
			else if(Var5 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4)
			else if(Var6 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4,Var5)
			else if(Var7 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4,Var5,Var6)
			else if(Var8 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4,Var5,Var6,Var7)
			else if(Var9 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8)
			else if(Var10 == "±")
				return %Function%(module,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9)
			else
				return %Function%(module,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
		}
		else
		{
			if(Var1 == "±")
				return %Function%()
			else if(Var2 == "±")
				return %Function%(Var1)
			else if(Var3 == "±")
				return %Function%(Var1,Var2)
			else if(Var4 == "±")
				return %Function%(Var1,Var2,Var3)
			else if(Var5 == "±")
				return %Function%(Var1,Var2,Var3,Var4)
			else if(Var6 == "±")
				return %Function%(Var1,Var2,Var3,Var4,Var5)
			else if(Var7 == "±")
				return %Function%(Var1,Var2,Var3,Var4,Var5,Var6)
			else if(Var8 == "±")
				return %Function%(Var1,Var2,Var3,Var4,Var5,Var6,Var7)
			else if(Var9 == "±")
				return %Function%(Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8)
			else if(Var10 == "±")
				return %Function%(Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9)
			else
				return %Function%(Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
		}
		return
	}
	module_func_namespace_exec(Namespace,Function,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±",byref Var10:="±")		{
		if(isfunc(Namespace "_" Function))
		{
			return this.module_func_mod_exec("",Namespace "_" Function,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
		}
		else
		{
			if(instr(Function, "."))
			{
				StringgetPos, pos,Function,.
				module:=SubStr(Function,1,pos)
				pos:=pos+2
				sub:="_" SubStr(Function,pos)
			}
			else
				module:=Function
			module:=module_manager.Core_format_module_natural(module)
			if(module != "")
				return this.module_func_mod_exec(module,module "." Namespace sub,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9,Var10)
		}
	}
	module_func_namespace_exists(Namespace,Function)	{
		if(isfunc(Namespace "_" Function))
		{
			return isfunc(Namespace "_" Function)
		}
		if(instr(Function, "."))
		{
			StringgetPos, pos,Function,.
			module:=SubStr(Function,1,pos)
			pos:=pos+2
			sub:="_" SubStr(Function,pos)
		}
		else
			module:=Function
		module:=module_manager.Core_format_module_natural(module)
		return isfunc(module "." Namespace sub)
	}
	extension_cleanup(skipreload:=0){
		extensions:=this.datastore_get("Extensions","extension",Array()), addedextensions:=this.datastore_get("Added_Extensions","extension",Array(),"file"), tobecleaned:=Array()
		Loop % Extensions.MaxIndex()
			if(!addedextensions.contains(Extensions[A_Index]))
				tobecleaned.push(Extensions[A_Index])
		Loop % tobecleaned.MaxIndex()
				this.extension_remove(tobecleaned[A_Index],2)
				
		if(tobecleaned.length() > 0 or !FileExist(this.extension_include()))
		{
			this.hook_hooks(-1)
			this.extension_include_generate(skipreload)
		}
	}
	extension_add(ExtensionName,skipreload:=0){
		StringLower, ExtensionName, ExtensionName
		this.module_checkinit()
		if(this.extension_exists(ExtensionName))
		{
			addedextensions:=this.datastore_get("Added_Extensions","extension",Array(),"file")
			if(!addedextensions.contains(ExtensionName))
			{
				addedextensions.push(ExtensionName)
				this.datastore_set("Added_Extensions","extension",addedextensions,"file")
			}
			extensions:=this.datastore_get("Extensions","extension",Array())
			if(!Extensions.contains(ExtensionName))
			{
				module_dependency.addDependent("module_manager",this.__Class,"module_extensionmanager", this.__Class "#" ExtensionName)
				Extensions.push(ExtensionName)
				this.config_set("Extensions","extension",extensions)
				this.hook_hooks(-1)
				this.extension_include_generate(skipreload)
			}
			this.datastore_add_Variable("extension_info",ExtensionName "_About", ExtensionName "_Version",ExtensionName "_UpdateURL",ExtensionName "_ChangeLog")
			return 1
		}
		else if(Extensions.contains(ExtensionName))
			this.extension_remove(ExtensionName)
		return 0
	}
	extension_remove(ExtensionName,skipreload:=0){
		StringLower, ExtensionName, ExtensionName
		this.module_checkinit()
		extensions:=this.datastore_get("Extensions","extension",Array())
		if(Extensions.contains(ExtensionName))
		{
			if(module_dependency.removeDependent("module_extensionmanager", this.__Class "#" ExtensionName))
			{
				addedextensions:=this.datastore_get("Added_Extensions","extension",Array(),"file")
				if(addedextensions.contains(ExtensionName))
				{
					addedextensions.removeAt(addedextensions.indexof(ExtensionName))
					this.datastore_set("Added_Extensions","extension",addedextensions,"file")
				}
				if(Extensions.contains(ExtensionName))
					Extensions.removeAt(Extensions.indexof(ExtensionName))
				if(Extensions.length() == 0)
					this.config_remove("Extensions","extension")
				else
					this.config_set("Extensions","extension",extensions)
				this.hook_hooks(-1)
				this.extension_include_generate(skipreload)
			}
		}
	}
	extension_include(){	
		return A_scriptdir "\Generated\Extension_" module_manager.Core_format_module_Readable(this) ".ahk"
	}
	extension_file(ExtensionName,force_not_dependent:=0)	{
		if(this.extension_exists(ExtensionName))
		{
			if(!this.extension_isModuleDependent(ExtensionName) or force_not_dependent)
				return A_ScriptDir module_manager.datastore_Get("Extensions","Core_Directory") "\" ExtensionName ".ahk"
			return A_ScriptDir module_manager.datastore_Get("Extensions","Core_Directory") "\" module_manager.Core_format_module_Readable(this) "\" ExtensionName ".ahk"
		}
	}
	extension_include_generate(skipreload:=0){
		this.extension_isModuleCompatible()
		if(!this.extension_isAllLoaded() and skipreload != 2 and !module_manager.Core_sandbox)
		{
			includefile:= this.extension_include()
			FileDelete, %includefile%
			extensiondir:=A_ScriptDir "\" module_manager.datastore_Get("Extensions","Core_Directory") "\" module_manager.Core_format_module_Readable(this)
			FileCreateDir, %extensiondir%
			generateddisclaimer:=";This File is Automatically Generated. To Add/Remove Extensions us the " this.__Class ".extension_add(<ExtensionName>) or  " this.__Class ".extension_remove(<ExtensionName>) Functions`n`n;The " this.__Class " class should contain the following to support extensions: #include *i %A_ScriptDir%\Generated\Extension_" module_manager.Core_format_module_Readable(this) ".ahk" "`n"
			FileAppend, %generateddisclaimer% ,%includefile%
			extensions:=this.datastore_get("Extensions","extension",Array())
			check_generate_include:="`nextension_generated_" this.__Class "(){`nreturn """ this.module_format_toString(Extensions) """ `;This is used to Verify what extensions were loaded at script start, and that the generated include file is included in script.`n} `n"
			FileAppend, %check_generate_include% , %includefile%
			Loop % Extensions.MaxIndex()
			{
				texttoinclude:="`n#IncludeAgain *i " this.extension_file(Extensions[A_Index]) " `;Include for " Extensions[A_Index]
				FileAppend, %texttoinclude% , %includefile%
			}
			if(Extensions.length() != 0)
				this.config_set("Extensions","extension",extension)
			else
				this.config_remove("Extensions","extension")
			if(!skipreload)
				module_manager.Core_configmode("reload")
		}
	}
	extension_exists(ExtensionName){
		return FileExist( A_ScriptDir module_manager.datastore_Get("Extensions","Core_Directory") "\" module_manager.Core_format_module_Readable(this) "\" ExtensionName ".ahk") or FileExist( A_ScriptDir module_manager.datastore_Get("Extensions","Core_Directory") "\" ExtensionName ".ahk")
	}
	extension_isModuleDependent(ExtensionName)	{
		return FileExist( A_ScriptDir "\" module_manager.datastore_Get("Extensions","Core_Directory") "\" module_manager.Core_format_module_Readable(this) "\" ExtensionName ".ahk")
	}
	extension_isModuleCompatible(){
		if(!isfunc(this.__Class ".extension_generated_" this.__Class) and FileExist(this.extension_include()) and !module_manager.Core_configmode(-2).contains("reload"))
		{
			if(!module_manager.Core_sandbox)
			{
			display_text:="Extension include was not found. `n Please add the following line to " this.__Class " so it support Extensions.`n#include *i %A_ScriptDir%\Generated\Extension_" module_manager.Core_format_module_Readable(this) ".ahk"
			msgbox,0,Extensions Not Compatible, %display_text%
			}
		}
		return isfunc(this.__Class ".extension_generated_" this.__Class)
	}
	extension_isLoaded(ExtensionNames*)	{
		LoadedExtensions:=this.module_format_toArray(this.module_func_exec(this.__Class ".extension_generated_" this.__Class))
		for index, ExtensionName in ExtensionNames
		{
			if(isobject(ExtensionName))
			{
				Loop % ExtensionName.MaxIndex()
				{
					ExtensionN:=ExtensionName[A_Index]
					StringLower ExtensionN,ExtensionN
					if(!LoadedExtensions.contains(ExtensionN))
						return 0
				}
			}
			else
			{
				StringLower ExtensionName,ExtensionName
				if(!LoadedExtensions.contains(ExtensionName))
					return 0
			}
		}
		return 1
	}
	extension_isAllLoaded()	{
		return this.extension_isLoaded(this.datastore_get("Extensions","extension",Array()))
	}
	extension_isCompatible(ExtensionName,ExtensionFile:="")	{
		if(!FileExist(ExtensionFile))
		{
			ExtensionFile:=this.extension_file(ExtensionName)
			if(!FileExist(ExtensionFile))
				return 0
		}
		if(!isobject(this.module_scriptfile_syntax(ExtensionFile)))
			return 0
		FileRead, filecontent, %ExtensionFile%
		Stringlower, filecontent,filecontent
		if(!InStr(filecontent, Format("{:L}",ExtensionName) "_"))
		{
			FileDelete %ExtensionFile%
			return 0
		}
		return 1
	}
	extension_configure(ExtensionName:="",returnfunc:="")	{
		static hreturnfunc
		if(this.extension_isLoaded(ExtensionName))
		{
			if(returnfunc != "")
				hreturnfunc:=returnfunc
			StringLower, ExtensionName,ExtensionName
			if(this.hook_hooks("extension_configure").contains(ExtensionName))
			{
				this.hook_single("extension_configure",ExtensionName)
				return
			}
			msg:=module_manager.Core_format_module_Readable(this) " - No Configuration function found for " ExtensionName "`n`n There is no " substr(this.hook_function_scheme("extension_configure",ExtensionNam),2) "(extendedmodule) function"
			MsgBox , 0, Configuration Function not found, %msg%
		}
		else
		{
			;Extension Is not loaded. Script needs to restart
		}
		if(hreturnfunc == "")
			module_extensionmanager.module_configure()
		else
		{
			this.module_func_exec(hreturnfunc)
			hreturnfunc:=""
		}
	}
	extension_update(ExtensionName:="", autoupdate:=0)	{
		;Updates extension Files
		if(ExtensionName == "")
		{
			Extensions:=this.datastore_get("Extensions","extension",Array())
			Loop % Extensions.MaxIndex()
				this.extension_update(Extensions[A_Index],autoupdate)
			return
		}
		if(this.extension_isLoaded(ExtensionName))
		{
			extensionident:=this.extension_update_ident(ExtensionName)
			if(autoupdate)	;Check if autoupdate should run
			{
				if(!module_manager.datastore_get("Extension_" extensionident,"AutoUpdate",1))
					return 0
				AutoUpdate_Check_Frequency:=module_manager.datastore_get("Check_Frequency","AutoUpdate",2)
				FormatTime, CurrentCheck,, YDay
				LastCheck:=module_manager.datastore_get("Extension_" extensionident,"AutoUpdate_LastCheck", -1)
				CurrentCheck:=CurrentCheck < LastCheck ? CurrentCheck + 365 : CurrentCheck
				UpdateCheck:=CurrentCheck - LastCheck
				if(UpdateCheck < AutoUpdate_Check_Frequency and LastCheck != -1)
					return 0
				module_manager.config_set("Extension_" extensionident,"AutoUpdate_LastCheck", CurrentCheck)
			}
			Updatefile:=this.extension_update_file(ExtensionName,1)
			ifExist, %UpdateFile%
			{
				currentversion:=this.datastore_get(ExtensionName "_Version","extension_info",0)
				newversion:=this.extension_update_extract(ExtensionName "_Version","extension_info",currentversion)
				if(currentversion < newversion)
				{
					changelog:=this.extension_update_extract(ExtensionName "_ChangeLog","extension_info","No ChangeLog Entry Found")
					title:="Update for Extension " extensionident
					msg:="New Version of " extensionident " available!`nCurrent Version: " currentversion "`nNew Version: " newversion "`nChangeLog:`n" changelog "`n`nDo you want to apply the update?`n(A Backup will be copied to Backup)"
					if(autoupdate)
						msgbox, 67, %title%, %msg%`n(Cancel Disables AutoUpdates)
					else
						msgbox, 68, %title%, %msg%
					ifmsgbox, yes
					{
						backupdir:=module_manager.datastore_get("Backup","Core_Directory")
						if(this.extension_isModuleDependent(ExtensionName))
							directory:=module_manager.datastore_Get("Extensions","Core_Directory") "\" module_manager.Core_format_module_Readable(this.__Class) "\"
						else
							directory:=module_manager.datastore_Get("Extensions","Core_Directory") "\"
						Filename:=ExtensionName ".ahk"
						backupdir.=directory
						;Needs work
						BackupFilename:=currentversion "_" Filename
						FileCreateDir, %backupdir%	;Creates backup directory
						FileCopy %A_ScriptDir%%directory%%Filename%,%backupdir%%BackupFilename%,1 ;Backs up previous file
						FileCopy, %UpdateFile%, %A_ScriptDir%%directory%%Filename%,1 ;Overrides old file with new file
						Patched_Extensions:=this.datastore_get("Patch","extension",Array())
						if(!Patched_Extensions.contains(ExtensionName))
						{
							Patched_Extensions.push(ExtensionName)
							this.config_set("Patch","extension",Patched_Extensions)
						}
						this.config_set(ExtensionName "_Patch","extension",currentversion)
						this.extension_include_generate()
						return 1
					}
					ifmsgbox, cancel
					{
						module_manager.config_remove("Extension_" extensionident,"AutoUpdate_LastCheck")
						module_manager.config_set("Extension_" extensionident,"AutoUpdate",0)
					}
				}
			}
		}
		return 0
	}
	extension_update_extract(ExtensionName,Variable,Namespace,DefaultValue:="")	{
		if(module_manager.Core_sandbox)
			return
		updatefile:=this.extension_update_file(ExtensionName)
		ifexist, %updatefile%
			return this.extension_sandbox_extract(ExtensionName,Variable,Namespace,DefaultValue,updatefile)
		return defaultvalue
	}
	extension_sandbox_extract(ExtensionName,Variable,Namespace,DefaultValue:="",ExtensionFile:="")	{
		if(module_manager.Core_sandbox)
			return
		cachedir:=module_manager.datastore_get("Temp","Core_Directory")
		sandboxfile:=cachedir "\sandbox_" this.__Class "_"  ExtensionName ".ahk"
		if(!FileExist(ExtensionFile))
		{
			ExtensionFile:=this.extension_file(ExtensionName)
			if(!FileExist(ExtensionFile))
				return
		}
		FileCopy %ExtensionFile%,%sandboxfile%,1
		testfilecontent:="#Include " A_ScriptDir "\Core\ModuleCore.ahk`nmodule_Manager.Core_sandbox:=1`nmodule_dummy." ExtensionName "_hook_module_init(module_dummy)`nvalue:=module_base.module_format_toString( module_dummy.datastore_get(""" variable """,""" namespace ""","""",""any""))`nFileAppend , %value%, %A_scriptdir%\extension_sandbox_extract.txt`nExitApp class module_dummy extends module_base{`n#Include *i " sandboxfile "`n}"
		fileappend %testfilecontent%, %cachedir%\extension_sandbox_extract.ahk
		runwait %A_AhkPath% "%cachedir%\extension_sandbox_extract.ahk"
		FileRead, output, %cachedir%\extension_sandbox_extract.txt
		output:=this.module_format_toArray(output)
		filedelete %cachedir%\extension_sandbox_extract.txt
		filedelete %cachedir%\extension_sandbox_extract.ahk
		FileDelete, %sandboxfile%
		return output==""?defaultvalue:output
	}
	extension_update_file(ExtensionName, clear:=0)	{
		if(this.extension_isLoaded(ExtensionName))
		{
			if(this.extension_isModuleDependent(ExtensionName))
				updatefile:=module_manager.datastore_get("Updates","Core_Directory") "\extension_" this.__Class "_" ExtensionName ".ahk"
			else
				updatefile:=module_manager.datastore_get("Updates","Core_Directory") "\extension_" ExtensionName ".ahk"
			UpdateURL:=this.module_DDLLink(this.datastore_get(ExtensionName "_UpdateURL","extension_info")) ;Gets File Download URL
			if(clear)
				FileDelete %updatefile%
			IfNotExist, %updatefile%
			{
				if(UpdateURL != "")
				{
					extensionident:=this.extension_update_ident(ExtensionName)
					module_manager.Core_LoadScreen("Updating",module_manager.Core_format_module_Readable(this) "-" ExtensionName)
					UrlDownloadToFile, %UpdateURL%, %UpdateFile%
					this.extension_isCompatible(ExtensionName,UpdateFile)
					module_manager.Core_LoadScreen()
				}
			}
			else if(UpdateURL == "")
				FileDelete %updatefile%
			return updatefile
		}
	}
	extension_update_ident(ExtensionName)	{
		return this.extension_isModuleDependent(ExtensionName) ? module_manager.Core_format_module_Readable(this.__Class) "_" ExtensionName : ExtensionName
	}
	extension_about(ExtensionName)	{
		if(this.extension_exists(ExtensionName))
		{
			if(this.extension_isLoaded(ExtensionName))
				abouttext:=this.datastore_get(ExtensionName "_About","extension_info","","any")
			else
				abouttext:=this.extension_update_extract(ExtensionName,ExtensionName "_About","extension_info")
			module_manager.about_notfound(abouttext,ExtensionName," If you are the programmer for this extension create a static variable named 'extension_info_" ExtensionName "_About'`nFor Version Tracking, Please create 'extension_info_" ExtensionName "_Version'`nFor checking on updates Create 'extension_info_" ExtensionName "_UpdateURL'")
			msgbox,32, About %ExtensionName%,%abouttext%
		}
		else
			msgbox,32, About %ExtensionName%,%ExtensionName% not found.
	
	}
	config_load(namespace:=""){
		if(module_manager.Core_sandbox)
			return
		if(this.hook(A_thisFunc,namespace))
			return  this.hook_value(A_thisFunc)
		ConfigVariables:=this.config_ConfigVariables(namespace,"load")
		if(ConfigVariables.contains("datastore"))
			this.config_val_Load("datastore",namespace)
		Loop % ConfigVariables.MaxIndex()
		{
			if(ConfigVariables[A_Index] != "datastore")
				this.config_val_Load(ConfigVariables[A_Index],namespace)
		}
		if(namespace == "")
		{
			Namespaces:=this.config_Namespaces("load")
				Loop % Namespaces.MaxIndex()
					this.config_load(Namespaces[A_Index])
				
		}
	}
	Config_Save(Namespace:=""){
		if(module_manager.Core_sandbox)
			return
		if(this.hook(A_thisFunc,namespace))
			return  this.hook_value(A_thisFunc)
		configvar:=this.config_ConfigVariables(namespace)
		Loop % configvar.MaxIndex()
			this.config_val_Save(configvar[A_Index],namespace)
		if(Namespace == "")
		{
			Namespaces:=this.Config_Namespaces()
			Loop % Namespaces.MaxIndex()
				this.Config_Save(Namespaces[A_Index])	
		}
	}
	config_val_Load(Variable,namespace:="",datastore:=""){
		if(this.hook(A_thisFunc, Variable, namespace))
			return  this.hook_value(A_thisFunc)
		Random RandomVal
		file:=A_ScriptDir "\configs\" this.datastore_Get("Config_File","module", module_manager.Core_format_module_Readable(this) ".ini")
		section:=namespace =="" ? module_manager.Core_format_module_Readable(this) : namespace
		IniRead, OutputVal, %file%, %section%, %Variable%, %RandomVal%
		if(OutputVal != RandomVal)
			this.datastore_Set(Variable,Namespace,this.module_format_toArray(OutputVal),datastore)
	}
	config_val_Save(Variable,namespace:="",datastore:=""){
		if(!module_manager.Core_sandbox)
		{
			if(this.hook(A_thisFunc,Variable,Namespace))
				return  this.hook_value(A_thisFunc)
			file:=A_ScriptDir "\configs\" this.datastore_Get("Config_File","module",module_manager.Core_format_module_Readable(this) ".ini"),	section:=namespace =="" ? module_manager.Core_format_module_Readable(this) : namespace
			Value:=this.module_format_toString(this.datastore_Get(Variable,Namespace,"",datastore))
			IniWrite, %Value%, %file%, %section%, %Variable%
		}
	}
	config_val_Delete(Variable,namespace:=""){
		if(!module_manager.Core_sandbox)
		{
			if(this.hook(A_thisFunc,Variable,namespace))
				return  this.hook_value(A_thisFunc)
			file:=A_ScriptDir "\configs\" this.datastore_Get("Config_File","module",module_manager.Core_format_module_Readable(this) ".ini")
			if(Variable == "" and Namespace == "")
			{
				filedelete, %file%
				return
			}
			section:=namespace == "" ? module_manager.Core_format_module_Readable(this) : namespace
			if(Variable == "")
				inidelete, %file%, %section%
			else
				inidelete, %file%, %section%, %Variable%
		}
	}
	config_set(Variable,namespace:="",Value:=""){
		if(value != "")
			this.datastore_Set(Variable,Namespace,Value)
		if(!this.config_isVal(Variable,Namespace))
		{
			ConfigVariables:=this.config_ConfigVariables(namespace)
			ConfigVariables.push(Variable)
			this.config_ConfigVariables(namespace,ConfigVariables)
		}
		this.hook(A_thisFunc,Variable,Namespace,Value)
		this.config_val_Save(Variable,Namespace)
	}
	config_add(Variable,namespace:="",DefaultValue:="")	{
		if(!this.config_isVal(Variable,Namespace))
			this.config_set(Variable,Namespace,DefaultValue)
		return this.datastore_Get(Variable,Namespace,DefaultValue)
	}
	config_remove(Variable,Namespace:=""){
		if(this.hook(A_thisFunc,Variable,Namespace))
			return  this.hook_value(A_thisFunc)
		if(this.config_isVal(Variable,Namespace))
		{
			this.datastore_Set(Variable,Namespace,"")
			ConfigVariables:=this.config_ConfigVariables(namespace)
			ConfigVariables.removeAt(ConfigVariables.indexof(Variable))
			this.config_ConfigVariables(namespace,ConfigVariables)
		}
	}
	config_isVal(Variable, Namespace:=""){
		if(this.hook(A_thisFunc,Variable,Namespace))
			return  this.hook_value(A_thisFunc)
		return this.config_ConfigVariables(namespace).contains(Variable)
	}
	config_addNamespace(Namespace){
		if(this.hook(A_thisFunc,Namespace))
			return  this.hook_value(A_thisFunc)
		if(!this.config_isNamespace(Namespace) and namespace != "")
		{
			namespaces:=this.config_Namespaces()
			namespaces.push(Format("{:L}", Namespace))
			this.config_Namespaces(namespaces)
		}
	}
	config_removeNamespace(Namespace){
		if(this.hook(A_thisFunc,Namespace))
			return  this.hook_value(A_thisFunc)
		if(this.config_isNamespace(namespace))
		{
			namespaces:=this.config_namespaces()
			if(namespaces.contains(Format("{:L}", Namespace)))
				namespaces.removeAt(namespaces.indexof(Format("{:L}", Namespace)))
			this.config_namespaces(namespaces)
		}
	}
	config_isNamespace(Namespace){
		if(this.hook(A_thisFunc,Namespace))
			return  this.hook_value(A_thisFunc)
		return this.config_namespaces().contains(Format("{:L}", Namespace)) or Namespace == ""
	}
	config_clear(){
		if(this.hook(A_thisFunc))
			return  this.hook_value(A_thisFunc)
		namespace:=this.config_Namespaces()
		Loop % namespace.MaxIndex()
				this.config_removeNamespace(namespace[A_Index])
		this.config_removeNamespace("")
	}
	config_Namespaces(newnamespaces:="",secondary:=0)	{
		static locked:=0
		if(isobject(newnamespaces))
		{
			if(!locked)
			{
				locked:=1
				oldnamespace:=this.config_namespaces()
				solidnamespaces:=0
				loop % oldnamespace.MaxIndex()
				{
					if(!newnamespaces.contains(oldnamespace[A_Index]))
					{
						this.config_ConfigVariables(oldnamespace[A_Index],Array())
						this.config_val_Delete("",oldnamespace[A_Index])
						this.config_val_Delete(oldnamespace[A_Index] "_ConfigVars","Config_" module_manager.Core_format_module_Readable(this))				
					}
					else if(this.config_ConfigVariables(oldnamespace[A_Index]).length() != 0)
						solidnamespaces++
				}
				this.datastore_set("Namespaces","Config_" module_manager.Core_format_module_Readable(this),newnamespaces,this.Config_set_ConfigHelper_Datastore())
				if((oldnamespace.length() > 0 and solidnamespaces == 0) or newnamespaces.length() == 0)
				{
					this.config_val_delete("Namespaces","Config_" module_manager.Core_format_module_Readable(this),this.Config_set_ConfigHelper_Datastore())
					if(this.config_ConfigVariables("").length() == 0)
						this.config_val_Delete("","")
				}
				else if(solidnamespaces>0)
					this.config_val_Save("Namespaces","Config_" module_manager.Core_format_module_Readable(this),this.Config_set_ConfigHelper_Datastore())
				locked:=0
			}
		}
		else if(newnamespaces == "load")
			this.config_val_Load("Namespaces","Config_" module_manager.Core_format_module_Readable(this),this.Config_set_ConfigHelper_Datastore())
		else if(newnamespaces == "contains")
			return this.config_namespaces().contains(Format("{:L}",secondary))

		return this.datastore_Get("Namespaces","Config_" module_manager.Core_format_module_Readable(this),Array(),this.Config_set_ConfigHelper_Datastore())
	}
	config_ConfigVariables(namespace,newconfigvariables:="")	{
		modulename:=module_manager.Core_format_module_Readable(this)
		if(newconfigvariables == "save")
			newconfigvariables:=this.config_ConfigVariables(namespace)
		if(isobject(newconfigvariables))
		{
			oldconfigvariables:=this.config_ConfigVariables(namespace)
			loop % oldconfigvariables.MaxIndex()
			{
				if(!newconfigvariables.contains(oldconfigvariables[A_Index]))
				{
					this.datastore_set(oldconfigvariables[A_Index],Namespace,"")
					this.config_val_Delete(oldconfigvariables[A_Index],Namespace)
				}
				else
					this.config_val_Save(oldconfigvariables[A_Index],Namespace)
			}
			this.datastore_Set(namespace "_ConfigVars","Config_" modulename,newconfigvariables,this.Config_set_ConfigHelper_Datastore())
			this.config_val_Save(namespace "_ConfigVars","Config_" modulename,this.Config_set_ConfigHelper_Datastore())
			if(!this.isNamespace(namespace) and namespace != "")
				this.config_addNamespace(namespace)
			if(newconfigvariables.length() == 0 and this.datastore_Variables(namespace).length() == 0)
				this.config_removeNamespace(namespace)
		}
		else if(newconfigvariables == "load")
			this.config_val_Load(namespace "_ConfigVars","Config_" modulename,this.Config_set_ConfigHelper_Datastore())
		return this.datastore_Get(namespace "_ConfigVars","Config_" modulename,Array(),this.Config_set_ConfigHelper_Datastore())
	}
	config_edit(ReturnFunction,Variables:="",Namespace:="")	{
		if(isobject(ReturnFunction))
		{
			if(ReturnFunction.root)
			{
				if(ReturnFunction.GuiAction == "Button1" or ReturnFunction.GuiAction == "GuiClose")
					return this.module_func_exec(ReturnFunction.ReturnFunction)
				if(ReturnFunction.GuiAction == "Button2" and ReturnFunction.vDropdownlist1 != "")
				{
					;THis is where it determines how to handle selected Item in root menu
					Loop % ReturnFunction.Variables.MaxIndex()
					{
						if(ReturnFunction.Variables[A_Index].Display == ReturnFunction.vDropdownlist1)
						{
							selected:=A_Index
							break
						}
					}
					module:=ReturnFunction.Variables[selected].module, InputType:=ReturnFunction.Variables[selected].InputType, Variable:=ReturnFunction.Variables[selected].Variable, Namespace:=ReturnFunction.Namespace,display:=ReturnFunction.Variables[selected].display
					if(InputType == "Inputbox" or InputType == "")
					{
						prompt:=ReturnFunction.Variables[selected].prompt == ""? "What should the value for " Display " be?":ReturnFunction.Variables[selected].prompt, itype:=ReturnFunction.Variables[selected].type
						currentvalue:=%module%.datastore_get(Variable,Namespace)
						InputBox, OutputVar , Edit %display%, %prompt%,,,,,,,,%currentvalue%
						if(!ErrorLevel)
						{
							if(itype == "")
								%module%.config_set(variable,namespace,OutputVar)
							else if OutputVar is %itype%
								%module%.config_set(variable,namespace,OutputVar)
							else
							{
								msgbox,0,Invalid Input, Invalid Input Type. %itype% Required.
								this.config_edit(ReturnFunction)
								return
							}
						}
					}
					else if(InputType == "Dropdownlist")
					{
						currentvalue:=%module%.datastore_get(Variable,Namespace)
						Dropdownlist:=ReturnFunction.Variables[selected].Dropdownlist,help:=ReturnFunction.Variables[selected].help
						guiinfo:={Dropdownlist1:Dropdownlist,Groupbox1:"Edit " display,Button1:"Help",Button2:"Done",Windowtitle:"Edit " Display,Dropdownlist1_ChooseString:currentvalue,Root:ReturnFunction,module:module,Variable:Variable,Namespace:Namespace,help:help}
						if(help == "")
						{
							guiinfo.Button1:="Done"
							module_guitemplate.OneButtonDropdown(A_thisFunc,guiinfo)
						}
						else
							module_guitemplate.TwoButtonDropdown(A_thisFunc,guiinfo)
						return
					}
					else if(InputType == "Function" and isfunc(ReturnFunction.Variables[selected].Function))
					{
						ReturnFunction.GuiAction:=""
						if(this.module_func_exec(ReturnFunction.Variables[selected].Function,ReturnFunction) != "")
							return
					}
				}
			}
			else
			{
				;Handles Dropdownlist Return
				guiinfo:=ReturnFunction
				ReturnFunction:=ReturnFunction.root
				if(((guiinfo.Template == "OneButtonDropdown" and guiinfo.GuiAction == "Button1") or (guiinfo.Template == "TwoButtonDropdown" and Guiinfo.GuiAction == "Button2")) and guiinfo.vDropdownlist1 != "")
				{
					module:=guiinfo.module,variable:=guiinfo.variable,namespace:=guiinfo.namespace
					%module%.config_set(variable,namespace,guiinfo.vDropdownlist1)
				}
				if(guiinfo.Template == "TwoButtonDropdown" and Guiinfo.GuiAction == "Button1")
				{
					help:=guiinfo.help
					msgbox, 0, Help, %help%
					this.config_edit(ReturnFunction)
					return
				}
			}
		}
		else if(isobject(Variables) and Variables.length() > 0)
		{
			;Sets up root menu
			loop % Variables.MaxIndex()
			{
				if(Variables[A_Index].Variable != "")
				{
					Variables[A_Index].module:=module_manager.Core_format_module_natural(Variables[A_Index].module)
					vardisplay:=Variables[A_Index].Variable
					StringReplace, vardisplay,vardisplay,_, %A_Space%, All
					if(Variables[A_Index].module != "")
					{
						Variables[A_Index].Display:=module_manager.Core_format_module_Readable(Variables[A_Index].module) "-" vardisplay
						varlist.="|" module_manager.Core_format_module_Readable(Variables[A_Index].module) "-" vardisplay
					}
					else
					{
						Variables[A_Index].module:=this.__Class
						Variables[A_Index].Display:=vardisplay
						varlist.="|" vardisplay
					}
				}
			}
			guiinfo:={Variables:Variables,Namespace:Namespace,ReturnFunction:ReturnFunction,Dropdownlist1:varlist,Groupbox1:"Configure Setting",Windowtitle:"Configure " Namespace,Button1:"Done", Button2:"Edit",root:1}
			ReturnFunction:=guiinfo
		}
		else
			return this.module_func_exec(ReturnFunction)
		module_guitemplate.TwoButtonDropdown(A_thisFunc,ReturnFunction)
	}
	Config_set_ConfigHelper_Datastore(Newdatastore:="")	{
		static datastore_helper:=Array()
		if(Newdatastore == "")
			return datastore_helper[ this.__Class] == "" ? "this_module" : datastore_helper[ this.__Class]
		if(this.datastore_isdatastore(Newdatastore))
		{
			StringLower, Newdatastore,Newdatastore
			Config_ConfigHelper_datastore:=this.Config_set_ConfigHelper_Datastore()
			namespaces:=this.config_Namespaces()
			Loop % namespaces.MaxIndex()
			{
				this.datastore_transfer_var(Config_ConfigHelper_datastore,Newdatastore,namespaces[A_Index] "_ConfigVars","Config_" module_manager.Core_format_module_Readable(this))
				this.datastore_transfer_var(Config_ConfigHelper_datastore,Newdatastore,namespaces[A_Index] "_Vars","Config_" module_manager.Core_format_module_Readable(this))
			}
			this.datastore_transfer_var(Config_ConfigHelper_datastore,Newdatastore,"_ConfigVars","Config_" module_manager.Core_format_module_Readable(this))
			this.datastore_transfer_var(Config_ConfigHelper_datastore,Newdatastore,"_Vars","Config_" module_manager.Core_format_module_Readable(this))
			this.datastore_transfer_var(Config_ConfigHelper_datastore,Newdatastore,"Namespaces","Config_" module_manager.Core_format_module_Readable(this))
			datastore_helper[ this.__Class]:=Newdatastore
		}
	}
	datastore_Variables(namespace,newvariables:="") {
		if(isobject(newvariables))
		{
			if(!this.isNamespace(namespace) and namespace != "")
				this.config_addNamespace(namespace)
			this.datastore_set(Namespace "_Vars","Config_" module_manager.Core_format_module_Readable(this),newvariables,this.Config_set_ConfigHelper_Datastore())
			if(this.config_ConfigVariables(namespace).length() == 0 and newvariables.length() == 0)
				this.config_removeNamespace(namespace)
		}
		return this.datastore_Get(Namespace "_Vars", "Config_" module_manager.Core_format_module_Readable(this), Array(), this.Config_set_ConfigHelper_Datastore())
	}
	datastore_get_Default_Datastore(Namespace)	{
		datastore:=this.datastore_get("datastore",namespace,this.datastore_set_Default_Datastore(),"natural_nms_this_module")
		if(!this.datastore_isdatastore(datastore,namespace))
			return this.datastore_set_Default_Datastore()
		return datastore
	}
	datastore_set_Default_Datastore(Newdatastore:=""){
		static datastore_default:=Array()
		if(Newdatastore == "")
			return datastore_default[ this.__Class] == ""?"this_module":datastore_default[ this.__Class]
		if(this.datastore_isdatastore(Newdatastore))
		{
			StringLower, Newdatastore,Newdatastore
			Config_Default_datastore:=this.datastore_set_Default_Datastore()
			datastore_default[ this.__Class]:=Newdatastore
			namespaces:=this.config_namespaces()
			Loop % namespaces.MaxIndex()
			{
				if(this.datastore_get("datastore",namespaces[A_Index],"") == "")
					this.datastore_set_Namespace_Datastore(namespaces[A_Index],Newdatastore,0,Config_Default_datastore)
			}
			if(this.datastore_get("datastore","","") == "")
				this.datastore_set_Namespace_Datastore("",Newdatastore,0,Config_Default_datastore)
		}
	}
	datastore_add_Variable(namespace, VariableNames*)	{
		Nonconfigvariable:=this.datastore_Variables(namespace)
		datastore:=this.datastore_get_Default_Datastore(Namespace)
		for index,VariableName in VariableNames
		{
			if(isobject(VariableName))
			{
				Loop % Variablename.MaxIndex()
				{
					if(!Nonconfigvariable.contains(VariableName[A_Index]) and !this.config_isVal(VariableName[A_Index],Namespace))
					{
						this.datastore_transfer_var("any",datastore,VariableName[A_Index],Namespace)
						Nonconfigvariable.push(VariableName[A_Index])
					}
				}
			}
			else	if(!Nonconfigvariable.contains(VariableName) and !this.config_isVal(VariableName,Namespace))
			{
				this.datastore_transfer_var("any",datastore,VariableName,Namespace)
				Nonconfigvariable.push(VariableName)
			}
		}
		this.datastore_Variables(namespace,NonConfigVariable)
	}
	datastore_set_Namespace_Datastore(namespace,Newdatastore,remember:=1,Olddatastore:=""){
		if(Newdatastore == "")
		{
			this.config_remove("datastore",namespace)
			Newdatastore:=this.datastore_set_Default_Datastore()
		}
		if(Olddatastore == "")
			Olddatastore:="any"
		configvariable:=this.config_ConfigVariables(namespace)
		Loop % configvariable.MaxIndex()
		{
				this.datastore_transfer_var(Olddatastore,Newdatastore,configvariable[A_Index],namespace)
		}
		Nonconfigvariable:=this.datastore_Variables(namespace)
		Loop % Nonconfigvariable.MaxIndex()
				this.datastore_transfer_var(Olddatastore,Newdatastore,Nonconfigvariable[A_Index],namespace)
		if(remember == 2)
			this.config_set("datastore",namespace,Newdatastore,"natural_nms_this_module")
		if(remember == 1)
			this.datastore_set("datastore",namespace,Newdatastore,"natural_nms_this_module")
	}
	datastore_get(Variable,Namespace:="",NotFoundValue:="",datastore:="")	{
		store:=this.datastore_store(0,Variable,Namespace,"",datastore)
		return store == "" ? NotFoundValue : store
	}
	datastore_set(Variable,Namespace:="",Value:="",datastore:="")	{
		return this.datastore_store(1,Variable,Namespace,Value,datastore)
	}
	datastore_delete(Variable,Namespace:="",datastore:="")	{
		return this.datastore_store(-1,Variable,Namespace,"",datastore)
	}
	datastore_store(Mode,Variable,Namespace,Value,datastore,ToAlldatastores:=0)	{
		static mem:=Array()
		StringLower, datastore,datastore
		isdatastore:=this.datastore_isdatastore(datastore,namespace)
		if(!isdatastore)
		{
			defaultdatastore:=this.datastore_get_Default_Datastore(Namespace)
			if(datastore != defaultdatastore)
				return this.datastore_store(mode,Variable,Namespace,Value,defaultdatastore,ToAlldatastores)
		}
		else
		{
			nat_datastore:=substr(datastore,1,12)
			if(nat_datastore == "natural_var_" or nat_datastore == "natural_nms_" or  nat_datastore == "natural_all_")
			{
				realdatastore:=substr(datastore,13)
				if(nat_datastore == "natural_nms_" or nat_datastore == "natural_all_")
				{
					StringLower, namespace,namespace
					namespace:=this.module_format_naturalize(Namespace,230,"{:L}")
				}
				if(nat_datastore == "natural_var_" or nat_datastore == "natural_all_")
				{
					StringLower, Variable,Variable
					Variable:=this.module_format_naturalize(Variable,230,"{:L}")
				}
			}
			else
				realdatastore:=datastore
			if(isdatastore == 1)
				return this.hook_single(A_thisFunc,realdatastore,Mode,Variable,Namespace,Value,datastore,ToAlldatastores)
			if(realdatastore == "this")
			{
				if(mode == 0)
				{
					if(namespace == "")
						return this[Variable]
					else
						return this[namespace "_" Variable]
				}
				else
				{
					if(namespace == "")
						this[Variable]:=Value
					else
						this[namespace "_" Variable]:=Value
					return 1
				}	
			}
			if(realdatastore == "this_module")
			{
			
				if(mode == 0)
				{
					if(namespace == "")
						return this[this.__Class "_" Variable]
					else
						return this[this.__Class "_" namespace "_" Variable]
				}
				else
				{
					if(namespace == "")
						this[this.__Class "_" Variable]:=Value
					else
						this[this.__Class "_" namespace "_" Variable]:=Value
					return 1
				}	
			
			;	if(mem[ this.__Class ] == "")
			;		mem[ this.__Class ]:=Array()
			;	if(mem[ this.__Class ]["#" namespace] == "")
			;		mem[ this.__Class ]["#" namespace]:=Array()
			;	if(mem[ this.__Class ]["#" namespace]["#" variable] == "")
			;		mem[ this.__Class ]["#" namespace]["#" variable]:=Array()
			;	if(mode == 0)
			;		return mem[ this.__Class ]["#" namespace]["#" variable]
			;	else	
			;		mem[ this.__Class ]["#" namespace]["#" variable]:=value
			;	return 1
				
			}
			if(realdatastore == "file")
			{
				if(module_manager.Core_sandbox)
					return this.datastore_store(mode,Variable,"file_" Namespace,Value,"natural_all_this_module")
				this.module_checkinit()
				namespace:=namespace == "" ? this.__Class : namespace,	file:=module_manager.datastore_get("Temp","Core_Directory") "\datastore_" this.__Class ".ini"
				if(mode == 0)
				{
					Random, RandomVal
					IniRead, OutputVal, %file%, %Namespace%, %Variable%, %RandomVal%
					return OutputVal == RandomVal ? "" : this.module_format_toArray(OutputVal)
				}
				if(mode == 1)
				{
					OutputVal:=this.module_format_toString(Value)
					IniWrite, %OutputVal%, %file%, %Namespace%, %Variable%
				}
				if(mode == -1)
					IniDelete, %file%, %Namespace%,%Variable%
				return 1
			}
			if(realdatastore == "any" or realdatastore == "all")
			{
				if(mode == 0)
				{
					test:=this.datastore_store(mode,Variable,Namespace,Value,this.datastore_get_Default_Datastore(Namespace))
					if(test != "")
						return test
				}
				datastores:=module_manager.Core_datastore_Builtin
				Loop, parse, datastores,`,
				{
					if(A_Loopfield != "any" and A_Loopfield != "all")
					{
						test:=this.datastore_store(mode,Variable,Namespace,Value,A_Loopfield,1)
						if(test != "" and mode == 0)
							return test
					}
				}
				hooks:=this.hook_hooks(A_thisFunc)
				loop % hooks.MaxIndex()
				{
					test:=this.datastore_store(mode,Variable,Namespace,Value,hooks[A_Index],1)
					if(test != "" and mode == 0)
						return test
				}
				if(mode != 0)
					return 1
			}
		}
		if(mode != 0)
			return 0
	}
	datastore_isdatastore(datastore:="",namespace:="")	{
		StringLower, datastore, datastore
		StringLower, namespace, namespace
		nat_datastore:=substr(datastore,1,12)
		if(nat_datastore == "natural_var_" or nat_datastore == "natural_nms_" or  nat_datastore == "natural_all_")
			datastore:=substr(datastore,13)
		datastores:=module_manager.Core_datastore_Builtin
		if datastore in %datastores%
			return 2
		builtinonly:=module_manager.Core_datastore_builtin_only_namespaces
		if namespace in %builtinonly%
			return 0
		return this.hook_hooks("module_base.datastore_store").contains(datastore) and datastore != ""
	}
	datastore_transfer_var(Olddatastore,Newdatastore,Variable,Namespace:=""){
		if(Olddatastore != Newdatastore and Variable != "datastore")
		{
			value:=this.datastore_Get(Variable,Namespace,"",Olddatastore)
			if(value != "")
			{
				this.datastore_delete(Variable,Namespace,Olddatastore)
				this.datastore_set(Variable,Namespace,value,Newdatastore)
			}
		}
	}
	;Runs Hook
	hook(function,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±"){
		if(isobject(function))
		{
			stop_on_return:=function.stop_on_return,	return_output:=function.return_output,	disable_override:=function.disable_override
			function:=function.function
		}
		IfnotinString, function,.
			function:=this.__Class "." function
		this.hook_override(-1)
		functions:=this.hook_functions(function)
		hooks:=this.hook_hooks(function)
		loop % functions.MaxIndex()	{
			hfunction:=functions[A_Index]
			IfInString, hfunction,.hook
				module_dependency.beginDependentBuild("module_manager",this.hook_module(hfunction))
			else
				module_dependency.beginDependentBuild("module_extensionmanager",hooks[A_Index])
			hook_output:=this.module_func_exec(hfunction,this,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9)
			module_dependency.endDependentBuild()
			output:=hook_output == ""? output : hook_output
			if(output != "" and (stop_on_return or (this.hook_override(-1) and !disable_override)))
				exit
		}
		this.hook_override(-1)
		if(return_output)
			return output
		if(output == "")
			return 0
		this.hook_value(function,output)
		return 1
	}
	hook_value(function,value:=""){
		static cache:=Array()
		StringReplace, cFunction,Function,.,_,All
		output:=cache[cFunction]
		cache[cFunction]:=value
		return output
	}
	hook_module(function)	{
		StringgetPos, pos,function,.
		return SubStr(function,1,pos)
	}
	;If Executed by a Hook then it overrides all any later hook.
	hook_override(state:=1){
		static sstate:=0
		if(state == -1)
		{
			out:=sstate
			sstate:=0
			return out
		}
		sstate:=state
	}
	hook_single(function,ident,byref Var1:="±",byref Var2:="±",byref Var3:="±",byref Var4:="±",byref Var5:="±",byref Var6:="±",byref Var7:="±",byref Var8:="±",byref Var9:="±"){
		hfunction:=this.hook_function_scheme(function,ident)
		if(isfunc(hfunction))
		{
			IfInString, function,.hook
				module_dependency.beginDependentBuild("module_manager",this.hook_module(hfunction))
			else
				module_dependency.beginDependentBuild("module_extensionmanager",hooks[A_Index])
			output:=this.module_func_exec(hfunction,this,Var1,Var2,Var3,Var4,Var5,Var6,Var7,Var8,Var9)
			module_dependency.endDependentBuild()
			return output
		}
	}
	;Returns the Function for each hook that implements the provided function
	hook_functions(function,clearcache:=0){
	static cache:=Array()
		if function is number
		{
			if(function == -1 or function == -2)
			{
				cache:=Array()
				if(function == -1)
					this.hook_hooks(-2)
			}
			else
				return cache
		}
		else
		{

			StringReplace, cFunction,Function,.,_,All
			if(clearcache)
				cache[cFunction]:=""
			if(cache[cFunction] != "")
				return cache[cFunction]
			hooks:=this.hook_hooks(function,clearcache)
			output:=Array()
			loop % hooks.MaxIndex()
				output.push(this.hook_function_scheme(function,hooks[A_Index]))
			if(this.hook_hooks(""))
				cache[cFunction]:=output
			return output
		}
	}
	;Returns the ident for each hook that implements the provided function
	hook_hooks(function,clearcache:=0){
	static cache:=Array(),cachestatus:=0
		if function is number
		{
			if(function == -1 or function == -2)
			{
				cache:=Array()
				if(function == -1)
					this.hook_functions(-2)
			}
			else if(function == -3)
				return cache
			else
				cachestatus:=function
		}
		else if(function == "")
			return cachestatus
		else
		{
			output:=Array()
			if(cachestatus != 2)
			{
				this.module_checkinit()
				StringReplace, cFunction,Function,.,_,All
				if(clearcache)
					cache[cFunction]:=""
				if(cache[cFunction] != "")
					return cache[cFunction]
				priorities:=""
				buildarray:=Array()
				extensions:=this.datastore_Get("Extensions","Extension",Array())
				loop % extensions.MaxIndex()
					this.hook_hooks_build(extensions[A_Index],"",function,priorities,buildarray)
				modules:=module_manager.datastore_Get("Modules","Core",module_manager.Core_default_modules())
				loop % modules.MaxIndex()
				{
					module:=modules[A_Index]
					this.hook_hooks_build("",module,function,priorities,buildarray)
					extensions:=this.Module_func_exec(module ".datastore_Get","Extensions","Extension",Array())
					loop % extensions.MaxIndex()
						this.hook_hooks_build(extensions[A_Index],module,function,priorities,buildarray)
				}
				if(priorities != "")
				{
					if(InStr(priorities,","))
					{
						Sort priorities, U N D,
						Loop, Parse, Priorities,`,
						{
							pri:="p" A_Loopfield
							Loop % buildarray[pri].MaxIndex()
								output.push(buildarray[pri][A_Index])
						}
					}
					else
					{
						pri:="p" priorities
						Loop % buildarray[pri].MaxIndex()
							output.push(buildarray[pri][A_Index])
					}
				}
				if(cachestatus)
					cache[cFunction]:=output
			}
			return output
		}
	}
	;Helps hook_hooks
	hook_hooks_build(extensionname,module,function,byref hpriority,byref buildarray){
		ident:=this.hook_ident(extensionname,module)
		if(isfunc(this.hook_function_scheme(function,ident)))
		{
			hpriority:=this.hook_priority(function,ident)
			priorities:= priorities=="" ? hpriority : priorities "," hpriority
			if(buildarray["p" hpriority] == "")
				buildarray["p" hpriority]:=Array()
			buildarray["p" hpriority].push(ident)
		}
	}
	;Formats the ident into the function name scheme for hook
	hook_function_scheme(function,ident){
		StringgetPos, pos,function,.
		if(!ErrorLevel)
		{
			hookModule:=SubStr(function,1,pos)
			pos:=pos+2
			hookfunction:=SubStr(function,pos)
			ifinstring, ident, #
			{
				StringgetPos, ipos,ident,#
				Module:=SubStr(ident,1,ipos)
				ipos:=ipos+2
				Extension:=SubStr(ident,ipos)
				if(Extension == "")
					return Module ".hook_" hookModule "_" hookfunction
				return Module "." Extension "_hook_" hookModule "_" hookfunction
			}
			return this.__Class "." ident "_hook_" hookfunction
		}
	}
	;Formats the Extension/Modulename into a hook ident
	hook_ident(ExtensionName,Module:=""){
		return !module_manager.isModule(Module) ? ExtensionName : isobject(Module) ? module_manager.Core_format_module_Readable(Module.__Class) "#" ExtensionName : module_manager.Core_format_module_Readable(Module) "#" ExtensionName 
	}
	;Sets Execution Priority for a Hook
	hook_priority(Function,Ident:="",hPriority:="",forcevalue:=0){
		static storage:=Array()
		StringReplace, cFunction,Function,.,_,All
		if(Ident == "")
			return storage[cFunction]
		if(hPriority is Number or (forcevalue and hPriority == ""))
		{
			storage[cFunction,ident]:=hPriority
			this.hook_functions(function,1)
		}
		return storage[cFunction,ident] == "" ? 100 : storage[cFunction,ident]
	}
}