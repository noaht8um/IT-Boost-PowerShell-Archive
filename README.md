This is a poorly written smattering of scripts related to a migration from ITBoost to Hudu performed in 2022. One of the main goals of the migration was preserving links between assets/documents/passwords/etc.
This uses an undocumented API in ITBoost (which might be gone by now) and also uses the [HuduAPI PowerShell Module](https://github.com/lwhitelock/HuduAPI).
The HuduMigration and ITBoostScripts directories contains misc migration scripts.
The ITBoostAPI Directory contains the ITBoost PowerShell Module.
To connect, you need to press F12 on a browser session while signed in to ITBoost and use the x-api-key and api-token parameters to connect. I don't remember if that's the exact names or where they can be found in DevTools.

