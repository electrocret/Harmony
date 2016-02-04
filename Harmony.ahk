;Basic performance optimization
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1

#include %A_ScriptDir%\core\HarmonyCore.ahk

;module_manager.Core_Preinit()

;module_manager.extension_add("log")
module_hotkey.trigger_reg("!m","radialmenu  main")
module_hotkey.trigger_reg("!n","test")
;module_base.extension_add("Emptymem")
;module_variablemanager.extension_add("cache_combine")
;module_variablemanager.extension_add("cache_traytip")
module_array.extension_add("emptymem")
module_includer.AddInclude("radialmenu","trigger")
module_includer.AddInclude("hotkey","trigger")
module_includer.AddInclude("hotstring","trigger")

module_manager.Core_Init()


