 TEAM R2R - KONTAKT Manager
-------------------------------------------------------------------------------
KONTAKT Manager is integrated library placer / keygen tool for KONTAKT 6.
It supports all required registration process instead of NativeAccess.

It can register all known libraries using custom minified database,
while it also supports registering unknown new libraries by using NICNT file.

This tool is useful for legit users too, check OPTION section in this text.
You can find the way to disable the keygen option.

* CAUTION *
- The library registration is for KONTAKT 6.
  Registered info is not always compatible former KONTAKT family.
- Generated license works in R2R release only.

-------------------------------------------------------------------------------
 USAGE
-------------------------------------------------------------------------------
KONTAKT Manager has 3 ways to register your libraries.
Locate All, Locate One, Locate by NICNT.


Locate All Libraries
--------------------
Run our KONTAKT Manager directly. 
It asks you to chose KONTAKT libraries folder.
Just select and click OK.
All libraries will be located and license will be generated.

The library folder is not searched recursively.
In the case below, when you select [YOUR_KONTAKT_LIBS_DIR],
only library A, B, D will be processed.

	---------------------
	YOUR_KONTAKT_LIBS_DIR
		+ LIBRARY A
		+ LIBRARY B
		|	+ LIBRARY C
		+ LIBRARY D
	---------------------

Unknown library will not be registered in this "Locate All" function.
You need to register unsupported libraries by using NICNT.


Locate One Library
------------------
Drag and drop one library folder to R2RKTMGR.exe.
The library will be registered.

Unknown library will not be registered in this "Locate All" function.
You need to register unsupported libraries by using NICNT.


Locate Library by NICNT
-----------------------
This can be useful for unknown new libraries.
Double click NICNT file, KONTAKT Manager will open.
Library will be located and licansed, using the information of that file.
This is the only way to process the library which is not in DB.

In this mode, KONTAKT Manager shows more detailed error information.
Most time, the error happens bacause of the tampered or broken NICNT.

-------------------------------------------------------------------------------
 Option
-------------------------------------------------------------------------------
You can set option by changing the value in the registry.

KEY : HKEY_CURRENT_USER\SOFTWARE\TEAM R2R\R2RKTMGR

[EnableKeygenFunction]
Set 0 to disable keygen.

[EnableFactoryLibrary2HotFix]
Set 1 to enable HotFix for "Kontakt Factory Library 2".
Its NICNT and NativeAccess.xml contain wrong HU/JDX value information.
This HotFix ignore the value from NICNT and DataBase, and put valid HU/JDX
value instead of them.

-------------------------------------------------------------------------------
 Version
-------------------------------------------------------------------------------

v1.1.13
- Update product database to 2024-SEP

v1.1.12
- Update product database to 2024-JUN

v1.1.11
- Update product database to 2024-FEB

v1.1.10
- Update product database to 2023-SEP

v1.1.9
- Update product database to 2023-JUN

v1.1.8
- Update product database to 2023-APR

v1.1.7
- Update product database to 2023-JAN

v1.1.6
- Update product database to 2022-DEC

v1.1.5
- HotFix function for "Kontakt Factory Library 2".
  This option is enabled by default.
  This function will be removed after Native Instruments fixed this issue.

v1.1.4
- Update product database to 2022-SEP

v1.1.3
- Update product database to 2022-AUG

v1.1.2
- Update product database to 2022-APR

v1.1.1
- Update product database to 2022-MAR.

v1.1.0
- KONTAKT Manager shows more detailed error in "Locate Library by NICNT" mode.
- Update product database to 2021-SEP-16.

v1.0.0
- First public version.

-------------------------------------------------------------------------------
                                                                  TEAM R2R 2022