#!/bin/bash
@echo off

	@echo off
	reg add "HKEY_CURRENT_USER\SOFTWARE\TEAM R2R\R2RKTMGR" /v "EnableFactoryLibrary2HotFix" /t REG_DWORD /d "0" /f >nul
