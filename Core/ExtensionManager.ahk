Class module_extensionmanager extends module_base{
#include *i %A_ScriptDir%\Generated\Extension_extensionmanager.ahk
	static module_about:="Extension Manager Manages Extensions to add/remove functionality from modules. `nBy Electrocret"
	static module_UpdateURL:="https://github.com/electrocret/Harmony/blob/master/Core/ExtensionManager.ahk"
		core_file()	{
		return A_LineFile
	}
	module_init()	{
		this.datastore_Set("Category","module","Core")
	}
	module_configure(guiinfo:="",secondaryguiinfo:="",thirdguiinfo:="")	{
		if(isobject(guiinfo))
		{
			if(guiinfo.Template == "TwoButtonDropdown")
			{
				;Main Menu
				if(guiinfo.GuiAction == "Button1" or Guiinfo.GuiAction == "GuiClose")
				{
					module_manager.module_configure()
					return
				}
				if(guiinfo.GuiAction == "Button2" and GuiInfo.vDropdownlist1 != "")
				{
					module:=module_manager.format_getModule(GuiInfo.vDropdownlist1)
					compatibility:=this.module_func_mod_exec(module ,"module_base.extension_check_compatibility")
					if(compatibility)
					{
						fmodule:=GuiInfo.vDropdownlist1
						extensions:=%module%.datastore_get("Extensions","extension",Array())
						Loop % extensions.MaxIndex()
							extensionlist.="|" Format("{:T}",extensions[A_Index])
						GInfo:={Windowtitle: "Extension Manager", groupbox1: fmodule " Extensions", Button1: "Add Extension",Button2: "Remove Extension",Button3: "Configure", Button4: "Done" ,ListBox1: extensionlist}
						module_guitemplate.manager(A_thisFunc,GInfo,guiinfo)
						return
					}
					if(compatibility == "")
					{
						msgbox,0,Extensions Not Compatible, %module% Does not properly extend the class module_base, and therefore does not support extensions.
					}
				}
			}
			else if(guiinfo.Template == "manager")
			{
				;Module manage extensions
				module:=module_manager.format_getModule(secondaryguiinfo.vDropdownlist1)
				if(guiinfo.GuiAction == "Button4" or Guiinfo.GuiAction == "GuiClose")
				{
					this.module_configure()
					return
				}
				if(guiinfo.GuiAction == "Button2" and guiinfo.vListBox1 != "")
				{
					selected:=guiinfo.vListBox1
					MsgBox, 4, Remove Extension, Are you sure you want to remove %selected%?
					ifmsgbox, yes
					{
						module_dependency.configuration_lock("module_extensionmanager",module "#" selected,0)
						%module%.extension_remove(selected)
					}
				}
				if(guiinfo.GuiAction == "Button1")
				{
					;Module Specific Extensions
					extensiondirectory:= A_ScriptDir "\" module_manager.datastore_Get("Extensions","Core_Directory") "\" secondaryguiinfo.vDropdownlist1 "\"
					extensions:=%module%.datastore_get("Extensions","extension",Array())
					Loop Files, %extensiondirectory%*.ahk
					{
						StringReplace, extension, A_LoopFileFullPath, %extensiondirectory%,
						Stringtrimright, extension, extension, 4
						if(!extensions.contains(extension))
							extensionlist.="|" extension
					}
					;General Extensions
					extensiondirectory:=A_ScriptDir "\" module_manager.datastore_Get("Extensions","Core_Directory") "\"
					extensions:=%module%.datastore_get("Extensions","extension",Array())
					Loop Files, %extensiondirectory%*.ahk
					{
						StringReplace, extension, A_LoopFileFullPath, %extensiondirectory%,
						Stringtrimright, extension, extension, 4
						if(!extensions.contains(extension))
							extensionlist.="|" extension
					}
					GInfo:={Windowtitle: "Add Extension", groupbox1: "Extensions", Button1: "Add Extension", Dropdownlist1: extensionlist}
					module_guitemplate.OneButtonDropdown(A_thisFunc,ginfo,guiinfo,secondaryguiinfo)
					return
				}
				if(guiinfo.GuiAction == "Button3" and guiinfo.vListBox1 != "")
				{
					%module%.extension_configure(guiinfo.vListBox1)
					return
				}
				this.module_configure(secondaryguiinfo)
				return
			}
			else if(guiinfo.Template == "OneButtonDropdown")
			{
				;Add New Extension
				if(guiinfo.GuiAction == "Button1" and guiinfo.vDropdownlist1 != "")
				{
					newextension:=guiinfo.vDropdownlist1
					module:=module_manager.format_getModule(thirdguiinfo.vDropdownlist1)
					module_dependency.configuration_lock("module_extensionmanager",module "#" newextension,1)
					test:=%module%.extension_add(newextension)
					if(test)
					{
						Msgbox, %newextension% Added!`nExtension will not be available until script restarts`n(Script Will Automatically Restart when you exit Configurations)
					}
					
				}
				this.module_configure(thirdguiinfo)
				return
			}
		}
		Modules:=module_manager.datastore_Get("Modules","Core")
		Loop % Modules.MaxIndex()
			modlist.="|" module_manager.format_remove(Modules[A_Index])
		GInfo:={Windowtitle: "Extension Manager", groupbox1: "Modules", Button1: "Done",Button2: "Edit Module Extensions",Dropdownlist1: modlist}
		module_guitemplate.TwoButtonDropdown(A_thisFunc,GInfo)
	}
	module_dependency(Directive,DependentName)	{
		DependentName:=module_dependency.parseDependent(DependentName)
		module:=DependentName.Handler
		Extension:=DependentName.Name
		if(Directive == "remove")
			return %module%.extension_remove(Extension)
		else if(Directive == "add")
			return %module%.extension_add(Extension)
		else if(Directive == "cleanup")
		{
			Modules:=module_manager.datastore_Get("Modules","Core")
			Loop % Modules.MaxIndex()
			{
				module:=Modules[A_Index]
				%module%.extension_cleanup()
			}
		}
	}
}