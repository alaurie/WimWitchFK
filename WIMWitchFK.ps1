<#PSScriptInfo

.VERSION 3.4.6

.GUID ee1ba506-ac68-45f8-9f37-4555f1902353

.AUTHOR Donna Ryan, Alex Laurie

.COMPANYNAME @TheNotoriousDRR, @alexon365

.COPYRIGHT

.TAGS WIM,Servicing,Offline Image Servicing

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

<#
.DESCRIPTION
 WIM Witch is a GUI driven tool used to update and customize Windows
 Image (WIM) files and ISOs. It can also create WIM configuration templates and
 apply them either with the GUI or programatically for bulk creation. WIM Witch
 works as a stand alone tool, as well as integrating with Configuration Manager

-version 3.4.6
General formatting tidy up.
Updated all null checks to follow PSScriptAnalyzer rules.
Updated all Functions to allow verb-noun rules.
Extracted any Functions within Functions into their own statement.

-version 3.4.5
Fix Win10 22H2 check box label on Updates tab
Added Win10 22H2 to the LP/LXP/FOD selection logic
Fix for Win10 22H2 updates downloading with ConfigMgr

-version 3.4.4
Support for Win10 22H2
Fixed bug when selection Windows 10 on Updates tab
Added try/catch to APPX removal Function

-version 3.4.3
Support for Win11 22H2
Support for x64 OneDrive client
Bugfix for OneDrive client not updating

-version 3.4.2
Bug Fix on greeting message that caused an error.


-version 3.4.1
Bug fix for applying .Net binaries to Windows 10 20H2
Bug fix for applying LCU to Windows 11
Added error output from DISM for .Net injection

 #>


#===========================================================================
# WIM Witch
#===========================================================================
#
# Written and maintained by: Donna Ryan
# Twitter: @TheNotoriousDRR
# www.TheNotoriousDRR.com
# www.MSEndpointMgr.com
#
# Current WIM Witch Doc (v3.3.0)
# https://msendpointmgr.com/2021/12/10/wim-witch-v3-3-0-remote-configuration-manager-integration/
#`
# Previous WIM Witch Doc (v3.2.0)
# https://msendpointmgr.com/2021/10/22/wim-witch-v3-2-0-windows-11-and-server-2022-support/
#
# Previous WIM Witch Doc (v3.1.0)
# https://msendpointmgr.com/2021/06/08/wim-witch-v3-1-21h1-support-some-fixes-some-bugs/
#
# Previous WIM Witch Doc (v3.0.0)
# https://msendpointmgr.com/2021/02/03/wim-witch-v3-0-0-configuration-manager-console-extension/
#
# Previous WIM Witch Doc (v2.3.0)
# https://msendpointmgr.com/2020/08/19/wim-witch-v2-3-0-iso-creation-upgrade-packages-optional-and-dynamic-updates-boot-wim-updating/
#
# Previous WIM Witch Doc (v2.2.0)
# https://msendpointmgr.com/2020/07/30/wim-witch-v2-2-0-start-menu-default-app-association-and-reg-file-support/
#
# Previous WIM Witch Doc (v2.1.0)
# https://msendpointmgr.com/2020/06/05/wim-witch-v2-1-minor-yet-major-updates-to-configmgr-integration-plus-windows-10-2004/
#
# Previous WIM Witch Doc (v2.0.0)
# https://www.scconfigmgr.com/2020/04/13/wim-witch-2-0-configmgr-integration/
#
# Previous WIM Witch Doc (v1.5.0)
# https://www.scconfigmgr.com/2020/03/04/deploying-autopilot-with-mdt-on-usb-a-wim-witch-use-case/
#
# Previous WIM Witch Doc (v1.4.0)
# https://www.scconfigmgr.com/2020/02/05/wim-witch-v1-4-0-language-packs-features-on-demand-and-local-experience-packs/
#
# Previous WIM Witch Doc (v1.3.0):
# https://www.scconfigmgr.com/2019/12/08/wim-witch-v1-3-0-server-support-onedrive-and-command-line/
#
# Previous WIM Witch Doc (v1.0):
# https://www.scconfigmgr.com/2019/10/04/wim-witch-a-gui-driven-solution-for-image-customization/
#
#===========================================================================
#
#
#
#################################################
#
# Community Contributions to WIM Witch
#################################################
#
# Mykael Niestrom - Update Function stolen with pride from one
# his projects. I'm pretty sure it was a hydration kit...
#
# Dave Segura - OneDrive download Function copied
# from OSDBuilder. Most importantly, the OSDSUS and OSDUPDATE Functions.
# WIM Witch wouldn't be where she is today without them. Thank you, David!
#
# Nickolaj Andersen - WIM Witch assimilated his ConfigMgr Software
# Update catalog Functions, adding their biological and technical
# distinctiveness to her own.
#
# Bryan Dam and Jordan Benzing - Sanity checks and stuPID
# questions.
#
# Michael Mardahl - Creating the ESD coversion process, and improvements
# to the whole ISO import Function
#
# Thanks to all of WIM Witch users who gave feed back, tested bugs,
# provided encouragement, and/or found WIM Witch usefull and
# spread the word.
#
###################################################

#====================================================================================================
#                                             Requires
#====================================================================================================
#region Requires

#Requires -Version 5.0
#-- Requires -Modules ActiveDirectory, AveoEmailNotifications
#-- Requires -ShellId <ShellId>
#Requires -RunAsAdministrator
#-- Requires -PSSnapin <PSSnapin-Name> [-Version <N>[.<n>]]


#============================================================================================================
Param(
    [parameter(mandatory = $false, HelpMessage = 'enable auto')]
    [switch]$auto,

    [parameter(mandatory = $false, HelpMessage = 'config file')]
    [string]$autofile,

    [parameter(mandatory = $false, HelpMessage = 'config path')]
    [string]$autopath,

    [parameter(mandatory = $false, HelpMessage = 'Update Modules')]
    [Switch]$UpdatePoShModules,

    [parameter(mandatory = $false, HelpMessage = 'Enable Downloading Updates')]
    [switch]$DownloadUpdates,

    [parameter(mandatory = $false, HelpMessage = 'Win10 Version')]
    [ValidateSet('all', '1809', '20H2', '21H1', '21H2', '22H2')]
    [string]$Win10Version = 'none',

    [parameter(mandatory = $false, HelpMessage = 'Win11 Version')]
    [ValidateSet('all', '21H2', '22H2')]
    [string]$Win11Version = 'none',

    [parameter(mandatory = $false, HelpMessage = 'Windows Server 2016')]
    [switch]$Server2016,

    [parameter(mandatory = $false, HelpMessage = 'Windows Server 2019')]
    [switch]$Server2019,

    [parameter(mandatory = $false, HelpMessage = 'Windows Server 2022')]
    [switch]$Server2022,

    [parameter(mandatory = $false, HelpMessage = 'This is not helpful')]
    [switch]$HiHungryImDad,

    [parameter(mandatory = $false, HelpMessage = 'CM Option')]
    [ValidateSet('New', 'Edit')]
    [string]$CM = 'none',

    [parameter(mandatory = $false, HelpMessage = 'Skip free space check')]
    [switch]$SkipFreeSpaceCheck,

    [parameter(mandatory = $false, HelpMessage = 'Used to skip lengthy steps')]
    [switch]$demomode

)

$WWScriptVer = '3.4.6'

#region XAML
#Your XAML goes here
$inputXML = @"
<Window x:Class="WIM_Witch_Tabbed.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WIM_Witch_Tabbed"
        mc:Ignorable="d"
        Title="WIM Witch - $WWScriptVer" Height="500" Width="800" Background="#FF610536">
    <Grid>
        <TabControl x:Name="TabControl" Margin="-3,-1,3,1" Background="#FFACACAC" BorderBrush="#FF610536" >
            <TabItem Header="Import WIM + .Net" Height="20" MinWidth="100">
                <Grid>
                    <TextBox x:Name="ImportISOTextBox" HorizontalAlignment="Left" Height="42" Margin="26,85,0,0" Text="ISO to import from..." VerticalAlignment="Top" Width="500" IsEnabled="False" HorizontalScrollBarVisibility="Visible"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,56,0,0" TextWrapping="Wrap" Text="Select a Windows ISO:" VerticalAlignment="Top" Height="26" Width="353"/>
                    <Button x:Name="ImportImportSelectButton" Content="Select" HorizontalAlignment="Left" Margin="553,85,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,149,0,0" TextWrapping="Wrap" Text="Select the item(s) to import:" VerticalAlignment="Top" Width="263"/>
                    <CheckBox x:Name="ImportWIMCheckBox" Content="Install.wim" HorizontalAlignment="Left" Margin="44,171,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="ImportDotNetCheckBox" Content=".Net Binaries" HorizontalAlignment="Left" Margin="44,191,0,0" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,240,0,0" TextWrapping="Wrap" Text="New name for the imported WIM:" VerticalAlignment="Top" Width="311"/>
                    <TextBox x:Name="ImportNewNameTextBox" HorizontalAlignment="Left" Height="23" Margin="26,261,0,0" TextWrapping="Wrap" Text="Name for the imported WIM" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Button x:Name="ImportImportButton" Content="Import" HorizontalAlignment="Left" Margin="553,261,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <CheckBox x:Name="ImportISOCheckBox" Content="ISO / Upgrade Package Files" HorizontalAlignment="Left" Margin="44,212,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="ImportBDJ" Content="Tell Me a Dad Joke" HorizontalAlignment="Left" Margin="639,383,0,0" VerticalAlignment="Top" Width="109" Visibility="Hidden"/>
                </Grid>
            </TabItem>
            <TabItem Header="Import LP+FOD" Margin="0" MinWidth="100">
                <Grid>
                    <TextBox x:Name="ImportOtherTBPath" HorizontalAlignment="Left" Height="23" Margin="49,92,0,0" TextWrapping="Wrap" Text="path to source" VerticalAlignment="Top" Width="339" IsEnabled="False"/>
                    <Button x:Name="ImportOtherBSelectPath" Content="Select" HorizontalAlignment="Left" Margin="413,94,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBlock HorizontalAlignment="Left" Margin="49,130,0,0" TextWrapping="Wrap" Text="Selected items" VerticalAlignment="Top"/>
                    <ComboBox x:Name="ImportOtherCBWinOS" HorizontalAlignment="Left" Margin="228,51,0,0" VerticalAlignment="Top" Width="120"/>
                    <ComboBox x:Name="ImportOtherCBWinVer" HorizontalAlignment="Left" Margin="371,50,0,0" VerticalAlignment="Top" Width="120"/>
                    <Button x:Name="ImportOtherBImport" Content="Import" HorizontalAlignment="Left" Margin="417,317,0,0" VerticalAlignment="Top" Width="75"/>
                    <ComboBox x:Name="ImportOtherCBType" HorizontalAlignment="Left" Margin="51,51,0,0" VerticalAlignment="Top" Width="160"/>
                    <TextBlock HorizontalAlignment="Left" Margin="51,26,0,0" TextWrapping="Wrap" Text="Object Type" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="230,32,0,0" TextWrapping="Wrap" Text="Windows OS" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="372,31,0,0" TextWrapping="Wrap" Text="Version" VerticalAlignment="Top"/>
                    <ListBox x:Name="ImportOtherLBList" HorizontalAlignment="Left" Height="149" Margin="49,151,0,0" VerticalAlignment="Top" Width="442"/>

                </Grid>

            </TabItem>
            <TabItem x:Name="CustomTab" Header="Pause + Scripts" MinWidth="100">
                <Grid>
                    <TextBox x:Name="CustomTBFile" HorizontalAlignment="Left" Height="23" Margin="49,157,0,0" TextWrapping="Wrap" Text="PowerShell Script" VerticalAlignment="Top" Width="501" IsEnabled="False"/>
                    <TextBox x:Name="CustomTBParameters" HorizontalAlignment="Left" Height="23" Margin="49,207,0,0" TextWrapping="Wrap" Text="Parameters" VerticalAlignment="Top" Width="501" IsEnabled="False"/>
                    <Button x:Name="CustomBSelectPath" Content="Select" HorizontalAlignment="Left" Margin="566,158,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <CheckBox x:Name="CustomCBRunScript" Content="Run Script" HorizontalAlignment="Left" Margin="49,102,0,0" VerticalAlignment="Top"/>
                    <ComboBox x:Name="CustomCBScriptTiming" HorizontalAlignment="Left" Margin="163,102,0,0" VerticalAlignment="Top" Width="172" IsEnabled="False"/>
                    <CheckBox x:Name="MISCBPauseMount" Content="Pause after mounting" HorizontalAlignment="Left" Margin="49,42,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="MISCBPauseDismount" Content="Pause before dismounting" HorizontalAlignment="Left" Margin="49,71,0,0" VerticalAlignment="Top"/>
                </Grid>
            </TabItem>
            <TabItem Header="Drivers" Height="20" MinWidth="100">
                <Grid>
                    <TextBox x:Name="DriverDir1TextBox" HorizontalAlignment="Left" Height="25" Margin="26,144,0,0" TextWrapping="Wrap" Text="Select Driver Source Folder" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Label x:Name="DirverDirLabel" Content="Driver Source" HorizontalAlignment="Left" Height="25" Margin="26,114,0,0" VerticalAlignment="Top" Width="100"/>
                    <Button x:Name="DriverDir1Button" Content="Select" HorizontalAlignment="Left" Height="25" Margin="562,144,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,20,0,0" TextWrapping="Wrap" Text="Select the path to the driver source(s) that contains the drivers that will be injected." VerticalAlignment="Top" Height="42" Width="353"/>
                    <CheckBox x:Name="DriverCheckBox" Content="Enable Driver Injection" HorizontalAlignment="Left" Margin="26,80,0,0" VerticalAlignment="Top"/>
                    <TextBox x:Name="DriverDir2TextBox" HorizontalAlignment="Left" Height="25" Margin="26,189,0,0" TextWrapping="Wrap" Text="Select Driver Source Folder" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Button x:Name="DriverDir2Button" Content="Select" HorizontalAlignment="Left" Height="25" Margin="562,189,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <TextBox x:Name="DriverDir3TextBox" HorizontalAlignment="Left" Height="25" Margin="26,234,0,0" TextWrapping="Wrap" Text="Select Driver Source Folder" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Button x:Name="DriverDir3Button" Content="Select" HorizontalAlignment="Left" Height="25" Margin="562,234,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <TextBox x:Name="DriverDir4TextBox" HorizontalAlignment="Left" Height="25" Margin="26,281,0,0" TextWrapping="Wrap" Text="Select Driver Source Folder" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Button x:Name="DriverDir4Button" Content="Select" HorizontalAlignment="Left" Height="25" Margin="562,281,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <TextBox x:Name="DriverDir5TextBox" HorizontalAlignment="Left" Height="25" Margin="26,328,0,0" TextWrapping="Wrap" Text="Select Driver Source Folder" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Button x:Name="DriverDir5Button" Content="Select" HorizontalAlignment="Left" Height="25" Margin="562,328,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                </Grid>
            </TabItem>
            <TabItem x:Name="AutopilotTab" Header="Autopilot" MinWidth="100">
                <Grid>
                    <TextBox x:Name="JSONTextBox" HorizontalAlignment="Left" Height="25" Margin="26,130,0,0" TextWrapping="Wrap" Text="Select JSON File" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Label x:Name="JSONLabel" Content="Source JSON" HorizontalAlignment="Left" Height="25" Margin="26,104,0,0" VerticalAlignment="Top" Width="100"/>
                    <Button x:Name="JSONButton" Content="Select" HorizontalAlignment="Left" Height="25" Margin="451,165,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,20,0,0" TextWrapping="Wrap" Text="Select a JSON file for use in deploying Autopilot systems. The file will be copied to processing folder during the build" VerticalAlignment="Top" Height="42" Width="353"/>
                    <CheckBox x:Name="JSONEnableCheckBox" Content="Enable Autopilot " HorizontalAlignment="Left" Margin="26,80,0,0" VerticalAlignment="Top" ClickMode="Press"/>
                    <TextBox x:Name="ZtdCorrelationId" HorizontalAlignment="Left" Height="23" Margin="129,176,0,0" TextWrapping="Wrap" Text="Select JSON File..." VerticalAlignment="Top" Width="236" IsEnabled="False"/>
                    <TextBox x:Name="CloudAssignedTenantDomain" HorizontalAlignment="Left" Height="23" Margin="129,204,0,0" TextWrapping="Wrap" Text="Select JSON File..." VerticalAlignment="Top" Width="236" IsEnabled="False"/>
                    <TextBox x:Name="Comment_File" HorizontalAlignment="Left" Height="23" Margin="129,232,0,0" TextWrapping="Wrap" Text="Select JSON File..." VerticalAlignment="Top" Width="236" IsEnabled="False"/>
                    <TextBlock HorizontalAlignment="Left" Margin="24,178,0,0" TextWrapping="Wrap" Text="ZTD ID#" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="24,204,0,0" TextWrapping="Wrap" Text="Tenant Name" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="24,233,0,0" TextWrapping="Wrap" Text="Deployment Profile" VerticalAlignment="Top"/>
                    <TextBox x:Name="JSONTextBoxSavePath" HorizontalAlignment="Left" Height="23" Margin="26,345,0,0" TextWrapping="Wrap" Text="$PSScriptRoot\Autopilot" VerticalAlignment="Top" Width="499" IsEnabled="False"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,275,0,0" TextWrapping="Wrap" Text="To download a new Autopilot profile from Intune, click select to choose the folder to save the file to. Then click Retrieve Profile." VerticalAlignment="Top" Height="48" Width="331"/>
                    <TextBlock HorizontalAlignment="Left" Margin="27,328,0,0" TextWrapping="Wrap" Text="Path to save file:" VerticalAlignment="Top"/>
                    <Button x:Name="JSONButtonSavePath" Content="Select" HorizontalAlignment="Left" Margin="450,373,0,0" VerticalAlignment="Top" Width="75"/>
                    <Button x:Name="JSONButtonRetrieve" Content="Retrieve Profile" HorizontalAlignment="Left" Margin="382,275,0,0" VerticalAlignment="Top" Width="130"/>
                </Grid>
            </TabItem>
            <TabItem Header="Save/Load" Height="20" MinWidth="102">
                <Grid>
                    <TextBox x:Name="SLSaveFileName" HorizontalAlignment="Left" Height="25" Margin="26,85,0,0" TextWrapping="Wrap" Text="Name for saved configuration..." VerticalAlignment="Top" Width="500"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,38,0,0" TextWrapping="Wrap" Text="Provide a name for the saved configuration" VerticalAlignment="Top" Height="42" Width="353"/>
                    <Button x:Name="SLSaveButton" Content="Save" HorizontalAlignment="Left" Margin="451,127,0,0" VerticalAlignment="Top" Width="75"/>
                    <Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="1" Margin="0,216,0,0" VerticalAlignment="Top" Width="785"/>
                    <TextBox x:Name="SLLoadTextBox" HorizontalAlignment="Left" Height="23" Margin="26,308,0,0" TextWrapping="Wrap" Text="Select configuration file to load" VerticalAlignment="Top" Width="500"/>
                    <Button x:Name="SLLoadButton" Content="Load" HorizontalAlignment="Left" Margin="451,351,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,279,0,0" TextWrapping="Wrap" Text="Select configuration file to load" VerticalAlignment="Top" Width="353"/>
                </Grid>
            </TabItem>
            <TabItem Header="Source WIM" Margin="0" MinWidth="100">
                <Grid>
                    <TextBox x:Name="SourceWIMSelectWIMTextBox" HorizontalAlignment="Left" Height="25" Margin="26,98,0,0" TextWrapping="Wrap" Text="Select WIM File" VerticalAlignment="Top" Width="500" IsEnabled="False" Grid.ColumnSpan="2"/>
                    <Label Content="Source Wim " HorizontalAlignment="Left" Height="25" Margin="26,70,0,0" VerticalAlignment="Top" Width="100"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,20,0,0" TextWrapping="Wrap" Text="Select the WIM file, and then Edition, that will serve as the base for the custom WIM." VerticalAlignment="Top" Height="42" Width="353" Grid.ColumnSpan="2"/>
                    <Button x:Name="SourceWIMSelectButton" Content="Select" HorizontalAlignment="Left" Height="25" Margin="450,153,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBox x:Name="SourceWIMImgDesTextBox" HorizontalAlignment="Left" Height="23" Margin="94,155,0,0" TextWrapping="Wrap" Text="ImageDescription" VerticalAlignment="Top" Width="339" IsEnabled="False"/>
                    <TextBox x:Name="SourceWimArchTextBox" HorizontalAlignment="Left" Height="23" Margin="94,183,0,0" TextWrapping="Wrap" Text="Architecture" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <TextBox x:Name="SourceWimVerTextBox" HorizontalAlignment="Left" Height="23" Margin="94,211,0,0" TextWrapping="Wrap" Text="Build" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <TextBox x:Name="SourceWimSPBuildTextBox" HorizontalAlignment="Left" Height="23" Margin="94,239,0,0" TextWrapping="Wrap" Text="SPBuild" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <TextBox x:Name="SourceWimLangTextBox" HorizontalAlignment="Left" Height="23" Margin="94,267,0,0" TextWrapping="Wrap" Text="Languages" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <Label Content="Edition" HorizontalAlignment="Left" Height="30" Margin="22,151,0,0" VerticalAlignment="Top" Width="68"/>
                    <Label Content="Arch" HorizontalAlignment="Left" Height="30" Margin="22,183,0,0" VerticalAlignment="Top" Width="68"/>
                    <Label Content="Build" HorizontalAlignment="Left" Height="30" Margin="22,211,0,0" VerticalAlignment="Top" Width="68"/>
                    <Label Content="Patch Level" HorizontalAlignment="Left" Height="30" Margin="22,239,0,0" VerticalAlignment="Top" Width="68"/>
                    <Label Content="Languages" HorizontalAlignment="Left" Height="30" Margin="22,267,0,0" VerticalAlignment="Top" Width="68"/>
                    <TextBox x:Name="SourceWimIndexTextBox" HorizontalAlignment="Left" Height="23" Margin="94,297,0,0" TextWrapping="Wrap" Text="Index" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <Label Content="Index" HorizontalAlignment="Left" Height="30" Margin="22,297,0,0" VerticalAlignment="Top" Width="68"/>
                    <TextBox x:Name="SourceWimTBVersionNum" HorizontalAlignment="Left" Height="23" Margin="94,325,0,0" TextWrapping="Wrap" Text="Version Number" VerticalAlignment="Top" Width="225" IsEnabled="False"/>
                    <Label Content="Version" HorizontalAlignment="Left" Height="30" Margin="22,321,0,0" VerticalAlignment="Top" Width="68"/>
                </Grid>
            </TabItem>
            <TabItem Header="Update Catalog" Height="20" MinWidth="100" Margin="-2,0,-2,0" VerticalAlignment="Top">
                <Grid>
                    <ComboBox x:Name="USCBSelectCatalogSource"  HorizontalAlignment="Left" Margin="26,48,0,0" VerticalAlignment="Top" Width="160" />
                    <TextBlock HorizontalAlignment="Left" Margin="91,275,0,0" TextWrapping="Wrap" Text="Installed version " VerticalAlignment="Top"/>
                    <TextBox x:Name="UpdatesOSDBVersion" HorizontalAlignment="Left" Height="23" Margin="91,297,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <Button x:Name="UpdateOSDBUpdateButton" Content="Install / Update" HorizontalAlignment="Left" Margin="218,362,0,0" VerticalAlignment="Top" Width="120"/>
                    <TextBlock HorizontalAlignment="Left" Height="42" Margin="31,85,0,0" TextWrapping="Wrap" Text="Select which versions of Windows to download current patches for. Downloading will also purge superseded updates." VerticalAlignment="Top" Width="335"/>
                    <CheckBox x:Name="UpdatesW10_1903" Content="1903" HorizontalAlignment="Left" Margin="67,183,0,0" VerticalAlignment="Top" IsEnabled="False" Visibility="Hidden"/>
                    <CheckBox x:Name="UpdatesW10_1809" Content="1809" HorizontalAlignment="Left" Margin="282,190,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW10_1803" Content="1803" HorizontalAlignment="Left" Margin="194,182,0,0" VerticalAlignment="Top" IsEnabled="False" Visibility="Hidden"/>
                    <CheckBox x:Name="UpdatesW10_1709" Content="1709" HorizontalAlignment="Left" Margin="251,182,0,0" VerticalAlignment="Top" IsEnabled="False" Visibility="Hidden"/>
                    <Button x:Name="UpdatesDownloadNewButton" Content="Download" HorizontalAlignment="Left" Margin="291,239,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBox x:Name="UpdatesOSDBCurrentVerTextBox" HorizontalAlignment="Left" Height="23" Margin="218,296,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <TextBlock HorizontalAlignment="Left" Margin="218,275,0,0" TextWrapping="Wrap" Text="Current Version" VerticalAlignment="Top"/>
                    <TextBlock x:Name="UpdatesOSDBOutOfDateTextBlock" HorizontalAlignment="Left" Margin="417,364,0,0" TextWrapping="Wrap" Text="A software update module is out of date. Please click the &quot;Install / Update&quot; button to update it." VerticalAlignment="Top" RenderTransformOrigin="0.493,0.524" Width="321" Visibility="Hidden"  />
                    <TextBlock x:Name="UpdatesOSDBSupercededExistTextBlock" HorizontalAlignment="Left" Margin="417,328,0,0" TextWrapping="Wrap" Text="Superceded updates discovered. Please select the versions of Windows 10 you are supporting and click &quot;Update&quot;" VerticalAlignment="Top" Width="375" Visibility="Hidden" />
                    <TextBlock x:Name="UpdatesOSDBClosePowerShellTextBlock" HorizontalAlignment="Left" Margin="417,292,0,0" TextWrapping="Wrap" Text="Please close all PowerShell windows, including WIM Witch, then relaunch app to continue" VerticalAlignment="Top" RenderTransformOrigin="0.493,0.524" Width="321" Visibility="Hidden"/>
                    <TextBlock HorizontalAlignment="Left" Margin="24,297,0,0" TextWrapping="Wrap" Text="OSDUpdate" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="26,334,0,0" TextWrapping="Wrap" Text="OSDSUS" VerticalAlignment="Top"/>
                    <TextBox x:Name="UpdatesOSDSUSVersion" HorizontalAlignment="Left" Height="23" Margin="91,330,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <TextBox x:Name="UpdatesOSDSUSCurrentVerTextBox" HorizontalAlignment="Left" Height="23" Margin="218,330,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW10Main" Content="Windows 10" HorizontalAlignment="Left" Margin="46,172,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesS2016" Content="Windows Server 2016" HorizontalAlignment="Left" Margin="44,251,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesS2019" Content="Windows Server 2019" HorizontalAlignment="Left" Margin="44,232,0,0" VerticalAlignment="Top"/>
                    <TextBlock x:Name="UpdatesOSDBClosePowerShellTextBlock_Copy" HorizontalAlignment="Left" Margin="26,27,0,0" TextWrapping="Wrap" Text="Select Update Catalog Source" VerticalAlignment="Top" RenderTransformOrigin="0.493,0.524" Width="321"/>
                    <ListBox x:Name="UpdatesOSDListBox" HorizontalAlignment="Left" Height="107" Margin="391,275,0,0" VerticalAlignment="Top" Width="347"/>
                    <CheckBox x:Name="UpdatesW10_2004" Content="2004" HorizontalAlignment="Left" Margin="193,175,0,0" VerticalAlignment="Top" IsEnabled="False" Visibility="Hidden"/>
                    <TextBlock HorizontalAlignment="Left" Margin="391,35,0,0" TextWrapping="Wrap" Text="Download Additional Update Types" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesCBEnableOptional" Content="Optional Updates" HorizontalAlignment="Left" Margin="421,55,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesCBEnableDynamic" Content="Dynamic Updates" HorizontalAlignment="Left" Margin="421,77,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesW10_20H2" Content="20H2" HorizontalAlignment="Left" Margin="225,190,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW10_21h1" Content="21H1" HorizontalAlignment="Left" Margin="169,190,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW11Main" Content="Windows 11" HorizontalAlignment="Left" Margin="46,135,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesS2022" Content="Windows Server 2022" HorizontalAlignment="Left" Margin="44,215,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesW10_21h2" Content="21H2" HorizontalAlignment="Left" Margin="112,190,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW11_22h2" Content="22H2" HorizontalAlignment="Left" Margin="58,153,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW11_21h2" Content="21H2" HorizontalAlignment="Left" Margin="111,153,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesW10_22h2" Content="22H2" HorizontalAlignment="Left" Margin="58,190,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                </Grid>
            </TabItem>
            <TabItem Header="Customizations" Height="20" MinWidth="100">
                <Grid>
                    <CheckBox x:Name="CustomCBLangPacks" Content="Inject Language Packs" HorizontalAlignment="Left" Margin="29,37,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="CustomBLangPacksSelect" Content="Select" HorizontalAlignment="Left" Margin="251,27,0,0" VerticalAlignment="Top" Width="132" IsEnabled="False"/>
                    <ListBox x:Name="CustomLBLangPacks" HorizontalAlignment="Left" Height="135" Margin="29,74,0,0" VerticalAlignment="Top" Width="355"/>
                    <TextBlock HorizontalAlignment="Left" Margin="32,55,0,0" TextWrapping="Wrap" Text="Selected LP's" VerticalAlignment="Top" Width="206"/>
                    <CheckBox x:Name="CustomCBFOD" Content="Inject Features on Demand" HorizontalAlignment="Left" Margin="419,126,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="CustomBFODSelect" Content="Select" HorizontalAlignment="Left" Margin="625,120,0,0" VerticalAlignment="Top" Width="133" IsEnabled="False"/>
                    <ListBox x:Name="CustomLBFOD" HorizontalAlignment="Left" Height="224" Margin="419,171,0,0" VerticalAlignment="Top" Width="340"/>
                    <TextBlock HorizontalAlignment="Left" Margin="421,147,0,0" TextWrapping="Wrap" Text="Select from imported Features" VerticalAlignment="Top" Width="206"/>
                    <CheckBox x:Name="CustomCBLEP" Content="Inject Local Experience Packs" HorizontalAlignment="Left" Margin="32,217,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="CustomBLEPSelect" Content="Select" HorizontalAlignment="Left" Margin="251,212,0,0" VerticalAlignment="Top" Width="132" IsEnabled="False"/>
                    <ListBox x:Name="CustomLBLEP" HorizontalAlignment="Left" Height="137" Margin="29,258,0,0" VerticalAlignment="Top" Width="355"/>
                    <TextBlock HorizontalAlignment="Left" Margin="32,237,0,0" TextWrapping="Wrap" Text="Selected LXP's" VerticalAlignment="Top" Width="206"/>
                    <CheckBox x:Name="MISDotNetCheckBox" Content="Inject .Net 3.5" HorizontalAlignment="Left" Margin="418,49,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="MISOneDriveCheckBox" Content="Update OneDrive client" HorizontalAlignment="Left" Margin="418,74,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="UpdatesEnableCheckBox" Content="Enable Updates" HorizontalAlignment="Left" Margin="580,49,0,0" VerticalAlignment="Top" ClickMode="Press"/>
                    <Button x:Name="CustomBLangPacksRemove" Content="Remove" HorizontalAlignment="Left" Margin="251,49,0,0" VerticalAlignment="Top" Width="132" IsEnabled="False"/>
                    <Button x:Name="CustomBLEPSRemove" Content="Remove" HorizontalAlignment="Left" Margin="251,235,0,0" VerticalAlignment="Top" Width="132" IsEnabled="False"/>
                    <Button x:Name="CustomBFODRemove" Content="Remove" HorizontalAlignment="Left" Margin="625,144,0,0" VerticalAlignment="Top" Width="133" IsEnabled="False"/>
                    <CheckBox x:Name="UpdatesOptionalEnableCheckBox" Content="Include Optional" HorizontalAlignment="Left" Margin="596,65,0,0" VerticalAlignment="Top" ClickMode="Press" IsEnabled="False"/>
                </Grid>
            </TabItem>
            <TabItem Header="Other Custom" Height="20" MinWidth="100">
                <Grid>
                    <ListBox x:Name="CustomLBRegistry" HorizontalAlignment="Left" Height="100" Margin="31,247,0,0" VerticalAlignment="Top" Width="440" IsEnabled="False"/>
                    <Button x:Name="CustomBRegistryAdd" Content="Add" HorizontalAlignment="Left" Margin="296,362,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <Button x:Name="CustomBRegistryRemove" Content="Remove" HorizontalAlignment="Left" Margin="391,362,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <CheckBox x:Name="CustomCBEnableRegistry" Content="Enable Registry Files" HorizontalAlignment="Left" Margin="31,227,0,0" VerticalAlignment="Top"/>
                    <TextBox x:Name="CustomTBStartMenu" HorizontalAlignment="Left" Height="23" Margin="31,174,0,0" TextWrapping="Wrap" Text="Select Start Menu XML" VerticalAlignment="Top" Width="440" IsEnabled="False"/>
                    <Button x:Name="CustomBStartMenu" Content="Select" HorizontalAlignment="Left" Margin="396,202,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <CheckBox x:Name="CustomCBEnableStart" Content="Enable Start Menu Layout" HorizontalAlignment="Left" Margin="30,152,0,0" VerticalAlignment="Top"/>
                    <TextBox x:Name="CustomTBDefaultApp" HorizontalAlignment="Left" Height="23" Margin="31,92,0,0" TextWrapping="Wrap" Text="Select Default App XML" VerticalAlignment="Top" Width="440" IsEnabled="False"/>
                    <Button x:Name="CustomBDefaultApp" Content="Select" HorizontalAlignment="Left" Margin="396,120,0,0" VerticalAlignment="Top" Width="75" IsEnabled="False"/>
                    <CheckBox x:Name="CustomCBEnableApp" Content="Enable Default App Association" HorizontalAlignment="Left" Margin="30,70,0,0" VerticalAlignment="Top"/>
                </Grid>
            </TabItem>
            <TabItem x:Name="AppTab" Header ="App Removal" Height="20" MinWidth="100">
                <Grid>
                    <TextBox x:Name="AppxTextBox" TextWrapping="Wrap" Text="Select the apps to remove..." Margin="21,85,252.2,22.8" VerticalScrollBarVisibility="Visible"/>
                    <TextBlock HorizontalAlignment="Left" Margin="21,65,0,0" TextWrapping="Wrap" Text="Selected app packages to remove:" VerticalAlignment="Top" Height="15" Width="194"/>
                    <CheckBox x:Name="AppxCheckBox" Content="Enable app removal" HorizontalAlignment="Left" Margin="21,33,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="AppxButton" Content="Select" HorizontalAlignment="Left" Margin="202,33,0,0" VerticalAlignment="Top" Width="75"/>
                </Grid>
            </TabItem>
            <TabItem Header="ConfigMgr" Height="20" MinWidth="102">
                <Grid>
                    <ComboBox x:Name="CMCBImageType" HorizontalAlignment="Left" Margin="39,37,0,0" VerticalAlignment="Top" Width="165"/>
                    <TextBox x:Name="CMTBPackageID" HorizontalAlignment="Left" Height="23" Margin="39,80,0,0" TextWrapping="Wrap" Text="Package ID" VerticalAlignment="Top" Width="120"/>
                    <TextBox x:Name="CMTBImageName" HorizontalAlignment="Left" Height="23" Margin="39,111,0,0" TextWrapping="Wrap" Text="Image Name" VerticalAlignment="Top" Width="290"/>
                    <ListBox x:Name="CMLBDPs" HorizontalAlignment="Left" Height="100" Margin="444,262,0,0" VerticalAlignment="Top" Width="285"/>
                    <TextBox x:Name="CMTBWinBuildNum" HorizontalAlignment="Left" Height="23" Margin="40,142,0,0" TextWrapping="Wrap" Text="Window Build Number" VerticalAlignment="Top" Width="290"/>
                    <TextBox x:Name="CMTBImageVer" HorizontalAlignment="Left" Height="23" Margin="41,187,0,0" TextWrapping="Wrap" Text="Image Version" VerticalAlignment="Top" Width="290"/>
                    <TextBox x:Name="CMTBDescription" HorizontalAlignment="Left" Height="91" Margin="41,216,0,0" TextWrapping="Wrap" Text="Description" VerticalAlignment="Top" Width="290"/>
                    <CheckBox x:Name="CMCBBinDirRep" Content="Enable Binary Differential Replication" HorizontalAlignment="Left" Margin="39,313,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="CMBSelectImage" Content="Select Image" HorizontalAlignment="Left" Margin="230,80,0,0" VerticalAlignment="Top" Width="99"/>
                    <TextBox x:Name="CMTBSitecode" HorizontalAlignment="Left" Height="23" Margin="444,112,0,0" TextWrapping="Wrap" Text="Site Code" VerticalAlignment="Top" Width="120"/>
                    <TextBox x:Name="CMTBSiteServer" HorizontalAlignment="Left" Height="23" Margin="444,153,0,0" TextWrapping="Wrap" Text="Site Server" VerticalAlignment="Top" Width="228"/>
                    <Button x:Name="CMBAddDP" Content="Add" HorizontalAlignment="Left" Margin="444,370,0,0" VerticalAlignment="Top" Width="75"/>
                    <Button x:Name="CMBRemoveDP" Content="Remove" HorizontalAlignment="Left" Margin="532,370,0,0" VerticalAlignment="Top" Width="75"/>
                    <ComboBox x:Name="CMCBDPDPG" HorizontalAlignment="Left" Margin="444,234,0,0" VerticalAlignment="Top" Width="228"/>
                    <CheckBox x:Name="CMCBDeploymentShare" Content="Enable Package Share" HorizontalAlignment="Left" Margin="39,333,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="CMCBImageVerAuto" Content="Auto Fill" HorizontalAlignment="Left" Margin="336,187,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="CMCBDescriptionAuto" Content="Auto Fill" HorizontalAlignment="Left" Margin="336,217,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="CMBInstallExtensions" Content="Install" HorizontalAlignment="Left" Margin="444,55,0,0" VerticalAlignment="Top" Width="75"/>
                    <TextBlock HorizontalAlignment="Left" Margin="445,36,0,0" TextWrapping="Wrap" Text="Click to install CM Console Extension" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="445,94,0,0" TextWrapping="Wrap" Text="Site Code" VerticalAlignment="Top"/>
                    <TextBlock HorizontalAlignment="Left" Margin="445,136,0,0" TextWrapping="Wrap" Text="Site Server" VerticalAlignment="Top"/>
                    <Button x:Name="CMBSetCM" Content="Set" HorizontalAlignment="Left" Margin="444,180,0,0" VerticalAlignment="Top" Width="75"/>

                </Grid>
            </TabItem>
            <TabItem Header="Make It So" Height="20" MinWidth="100">
                <Grid>
                    <CheckBox x:Name="MISCBCheckForUpdates" Margin="544,19,15,376" Content="Check for updates when running" />
                    <Button x:Name="MISFolderButton" Content="Select" HorizontalAlignment="Left" Margin="444,144,0,0" VerticalAlignment="Top" Width="75" RenderTransformOrigin="0.39,-2.647"/>
                    <TextBox x:Name="MISWimNameTextBox" HorizontalAlignment="Left" Height="25" Margin="20,85,0,0" TextWrapping="Wrap" Text="Enter Target WIM Name" VerticalAlignment="Top" Width="500"/>
                    <TextBox x:Name="MISDriverTextBox" HorizontalAlignment="Left" Height="23" Margin="658,345,0,0" TextWrapping="Wrap" Text="Driver Y/N" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <Label Content="Driver injection?" HorizontalAlignment="Left" Height="30" Margin="551,343,0,0" VerticalAlignment="Top" Width="101"/>
                    <TextBox x:Name="MISJSONTextBox" HorizontalAlignment="Left" Height="23" Margin="658,374,0,0" TextWrapping="Wrap" Text="JSON Select Y/N" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                    <Label Content="JSON injection?" HorizontalAlignment="Left" Margin="551,372,0,0" VerticalAlignment="Top" Width="102"/>
                    <TextBox x:Name="MISWimFolderTextBox" HorizontalAlignment="Left" Height="23" Margin="20,115,0,0" TextWrapping="Wrap" Text="$PSScriptRoot\CompletedWIMs" VerticalAlignment="Top" Width="500"/>
                    <TextBlock HorizontalAlignment="Left" Margin="20,20,0,0" TextWrapping="Wrap" Text="Enter a name, and select a destination forlder, for the  image to be created. Once complete, and build parameters verified, click &quot;Make it so!&quot; to start the build." VerticalAlignment="Top" Height="60" Width="353"/>
                    <Button x:Name="MISMakeItSoButton" Content="Make it so!" HorizontalAlignment="Left" Margin="400,20,0,0" VerticalAlignment="Top" Width="120" Height="29" FontSize="16"/>
                    <TextBox x:Name="MISMountTextBox" HorizontalAlignment="Left" Height="25" Margin="19,191,0,0" TextWrapping="Wrap" Text="$PSScriptRoot\Mount" VerticalAlignment="Top" Width="500" IsEnabled="False"/>
                    <Label Content="Mount Path" HorizontalAlignment="Left" Margin="19,166,0,0" VerticalAlignment="Top" Height="25" Width="100"/>
                    <Button x:Name="MISMountSelectButton" Content="Select" HorizontalAlignment="Left" Margin="444,221,0,0" VerticalAlignment="Top" Width="75" Height="25"/>
                    <Label Content="Update injection?" HorizontalAlignment="Left" Margin="551,311,0,0" VerticalAlignment="Top" Width="109"/>
                    <TextBox x:Name="MISUpdatesTextBox" HorizontalAlignment="Left" Height="23" Margin="658,314,0,0" TextWrapping="Wrap" Text="Updates Y/N" VerticalAlignment="Top" Width="120" RenderTransformOrigin="0.171,0.142" IsEnabled="False"/>
                    <Label Content="App removal?" HorizontalAlignment="Left" Margin="551,280,0,0" VerticalAlignment="Top" Width="109"/>
                    <TextBox x:Name="MISAppxTextBox" HorizontalAlignment="Left" Height="23" Margin="658,283,0,0" TextWrapping="Wrap" Text="Updates Y/N" VerticalAlignment="Top" Width="120" RenderTransformOrigin="0.171,0.142" IsEnabled="False"/>
                    <CheckBox x:Name="MISCBDynamicUpdates" Margin="544,40,15,355" Content="Apply Dynamic Update" IsEnabled="False" />
                    <CheckBox x:Name="MISCBBootWIM" Margin="544,62,15,337" Content="Update Boot.WIM" IsEnabled="False" />
                    <TextBox x:Name="MISTBISOFileName" HorizontalAlignment="Left" Height="23" Margin="21,268,0,0" TextWrapping="Wrap" Text="ISO File Name" VerticalAlignment="Top" Width="498" IsEnabled="False"/>
                    <TextBox x:Name="MISTBFilePath" HorizontalAlignment="Left" Height="23" Margin="21,296,0,0" TextWrapping="Wrap" Text="ISO File Path" VerticalAlignment="Top" Width="498" IsEnabled="False"/>
                    <CheckBox x:Name="MISCBISO" Content="Create ISO" HorizontalAlignment="Left" Margin="21,248,0,0" VerticalAlignment="Top"/>
                    <CheckBox x:Name="MISCBNoWIM" Margin="544,85,15,312" Content="Do Not Create Stand Alone WIM" IsEnabled="False"/>
                    <TextBox x:Name="MISTBUpgradePackage" HorizontalAlignment="Left" Height="23" Margin="23,368,0,0" TextWrapping="Wrap" Text="Upgrade Package Path" VerticalAlignment="Top" Width="494" IsEnabled="False"/>
                    <CheckBox x:Name="MISCBUpgradePackage" Content="Upgrade Package Path" HorizontalAlignment="Left" Margin="22,347,0,0" VerticalAlignment="Top"/>
                    <Button x:Name="MISISOSelectButton" Content="Select" HorizontalAlignment="Left" Margin="444,324,0,0" VerticalAlignment="Top" Width="75" Height="25" IsEnabled="False"/>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
    <Window.TaskbarItemInfo>
        <TaskbarItemInfo/>
    </Window.TaskbarItemInfo>
</Window>
"@

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace 'x:N', 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[xml]$XAML = $inputXML
#Read XAML

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $Form = [Windows.Markup.XamlReader]::Load( $reader )
}
catch {
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================

$xaml.SelectNodes('//*[@Name]') | ForEach-Object { "trying item $($_.Name)" | Out-Null
    try { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
    catch { throw }
}

#Section to do the icon magic
###################################################
$base64 = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAHYcAAB2HAY/l8WUAABtaSURBVHhe7VoHWFTXtk5iij5L7I0mIFJUpHcYht4Zeu8wOErvgtJ7FekoghRFEEGqYsEeCyIgiNJsMZY0701iclVYb+3DYNCbe6MGc/Ped9f37W8GPbPP+df6V9lrnQ/+K/+V6ZHB7OzPRgID9W+xPKPvBAXtvhsWdnmUyRwZsbYeuaGlOdInJTV8TVL8dK+wUFG/rPTWUVdXowfl5bMB4EP2Fv/3pDQqan76xo3imQ4OYbG6ug2JJiYX02xsuuL19c+mMBjfxuvqQpi0NASKikK4nCzEKShAsSoNThkawGVJceiXEPvluphox5CurtdDFosPampmsLf+60tzVdWCoqgorTwmk35GR8e1V0YmuUdEuL2Hj3fo6splX3dzrXzay88L1wT4oVtQAC4KC8FRIUEo5eOFqMWLwX/lSoiVlIB6NTpco9PGb64V/mZIUqxk1NRI5S+vCIiK+mjI2YqrV1w8q4ef7+aVxYuedy2YD10L58PVhQuge9FC6F68EHoWL4KeJYugd+liuLZsCbX6li+FvhXLoBM/m/CalM/ngR8nFxQqK0O/vi4MrhX+cUReru6Wg4PwX849ohB4p63t+l5F+eKu5ct++k3QCHgqaAowe/Uj8Osrl1NrgGMF3OBcSa2r+H0P7hGydAmUaqjDNTVVGF4v8rdROi3hQWDgUvbt/7PS6u29pE1SMukC58rvJkDjWoTAEXT3JGgCVEQIulSUoF1eDg5IS0E1rv2y0nBIQR5O0VWhX1cbhhXkYHA1Hwxyc04sHi4YXMUF3fi9DPeLRDdpJdfJy4yPSohevOdoS/9PsuHDKjU1mQY+3qsXFy8cfwl6kt5o5avo520K8i8y5WV/8F23bmizpGQXU1KyyUVEZJ/7etEWFyGhHvOlS2/bcXC8sFu+HDy5uCBRQhyaDfShX1sThkXXwhD/Klw81OclHk5Iwb1z5GVhQEcTRsVFv71nqO9HMg37mf4cIZQvV1U1q1m8+NtONvBJehPg3UKCz47pal9L1NfNjLO318nCrLBzZ/nq2IRs820xaZHxSdm7ElJyjiSm5J5N317UXbK7arwgKw+2OLiCh4w8mC9aDFZzZkMysqVdRwuGaEowIiwAI2v4YAhXDbpMnMBquGSoD3ckNjz/UoNeuMs7QDw0NPlz9iO+PyGUK1dSsihdtOBvnQic8mn0UcqvOVaM3ZCRrjvn7q5dkZ09r7W19bOU9Hyj8MiU2tCIxEfBW+LH8RO2bEuGiKhU2BqdBpGxGRAdnwWxidshLikbUDEQF5kIwQ5u4CYuBZbz5kEYZok2PR0YVVWG2yICcBuVcQpdI5aTAzoM9OCujCRUiUv9Q1darcHAwGYx+1Hfj5QqKSlmz5374Dxafmowu87D9cOwqkrIrdLSmR0dHR+npxcpIcgTIeHxvxDQYVuTABXxEnRUfCbEJEyATkrLg4ztxbAjdzfsyCuFvMI9ULizEgqKyiEjIQP8NHXAcdEiiBQRgU5TY7grLQF31wpClwAfJC5fBseQCfdkJKBSeN2Yroxmi79/1EL2406v1Li4LMlcsqT/0OdzX4neA6u4fxwxNnBHdnyUmJG7OjImrRQB//w66GgEHcsGnZiaA8kIPCQsfpy5MeRHMwv3J4rKRk/EJTWfiEuo/6igaDBmYuoCmzZvgcjodMhO3g4hWrrghrXCXk0NuK2lDvc3rIU+ZEPisqVwApnwQF4aKteKjhsrG9S6uflPrxII9XP4+VOyZ82Eq1NS1gA354sROi2sr6bm04jIJIugLfG3XrF0HLF01kt6J6XlQlpmwc/RMek9rM2hOdr6NtpmZq7iDIaDsIMDS5hh5SZsbOEkpq1tqWFu7hpLo5uelJXT/ZuyijHYWHtChMsm2LiKD5JF18OQsQE8kNwA10TWQDK6w0VkwgN0h6L1Es8ttS3TMFbNZD/+H5dKPT2xxNmzv29Af3+Zq7k4xkcV5WoHUlLm+gdGBvsGRv60LSZ9CujtEJ+8A5JScyE5PR9SMgp+yc7dVdHc3C6MD/c/uO3vpjC87tP4+AwOI4ZDgKqqSZesnP5zI3XGz05Llv0SxsMDPSZG8Ajpf0lwNSSt4oFBhiHcRxdJFZf7hzXD1YOwkr3VuwuJ+hlcXLmJn3wC3ZjabnJxTORpYcG7w842Al7+WwNZ3lueEYpTlkbQiRToPEjNLACM9JC5Y+fT/OI9iTU1NbPInjV9fZ9irJhP3eANJSMjY5atw2YDV1dv8Vg63ch9zpz7wVg695gy4Gs5KTjCtwpyxcTgoa4WxgQpCJBWfejjE6H0h2uFOhOTFUkLFtzOx6qOKk5w3eTlHrulqxUYHBZr5OTm+/eouIwJvyagMyZBF8P23BLIzts9ll9UsbuoqIhY/YO07fnrinfvjWluPspH3eAdhICKkpHRcp89+04oBwcMoBIeoxJ2rlgOLZrq8B1dGbpkZWCjruXF7OxiTvbP3k3yxcWtIz/6EKq50Oq83DCEa0RS7MuKqBQJR2fvoaCwOEJvBF1ILA1ZObsIaMgpKIM8jOSFJZUXm5ublxd1dn6yNSrVOT276GHF3oPJJFuwb/FOQpQQJyen4zl37uNYfn64jTFhGGNCCsdKuGmoB0+U5KBaTnnM28UntRPvzf7Z20sqN3fetg8/hA4x0YnKbPWq8RENtVQmKygbrU/R/HXQBTsroHBXFRSX7v22Yt9BrWys1gJCY8LQTX7Gvx/X1TVKsLf/Q0Lcc6uoqKPnZ589LZCSgMd62tCKJXOZjDR8r60Oj5QVIFLD4El2dhGN/ZO3k46oqI/T+fhGI2fMgG6s3YcFeGF4rdBPLbEJDBv7Td8HBMewQe/5FfTufbCrrBpK9uwfL99XV9zaOviZj3+km29Q1NM9ew9AzcGW00eOdM9m3+IPS42FxacRgoJZmz/77EW7rg58haAzsD64zjCCp6pKcEZJGQKZAS19fX1z2D95czmTlLQg8pNPfomdORP6xNbDqCA/3JKRuMxi+qVb2W2EtKyiV0DvLq+BssoDsGdvHVRW139TXdcqF7YtUd7F3f+73MIyOHCoDQ41t2ewt582KcEaJWDxko7QhYtgxIwBR9eshjIpSfjJQAeeqqlAopr+D6GhcUrsy99cdmtoCGxD68dhbd6/ThhuYeEx7Mm84uLud5/Qn4AnoEsra2FPVR0gvaFqfwPsrT0E+w82t+Tnly91YwacCAyJgfqmI9DUemys6fBxV/b20yppioqq3rNmfbcbgd/VVMOD02IYNdKHZxqqcFGVPu5sZJ+FgfjtYkGugoJYOPp/7Nw5MCAqAndxdRYUgjVaf7NvBGXpcgRdub+eAl1d1wQ19S1QW9/yvL6x3d3LZ4ubrePmZzn5u6HtyAk40t4xdvz4SVv29tMqnQgugocnJ3g2GgvpX43Z6rA6HZ7ra8MPqJBwNf2BgIAILvblbyYVZmZaoaiAaFTADQlRuCcrCRWxSWBi4UrlfAr0AQR9sBlqG1qhrvEwNDS3w6GWo08OHmyTd3b3O+/i4Q/NrUfhRMcZ6Dh5duz0uQvm7O2nXfIYDOEArA8K1opAO7pBBlaId5UU4BspcaiSVRpjufoFVVU1L2Bf/vtSbmnJIArY9j+zYFBJHu6pKEKEpy+YmLtANuZ4AvogBfoINLYeg+a242jpDjhy9OSNLVuTTa1sPV8EhsQi8HNw5uwFOHf+0otLl66YsrefdsGAOCOSmzsrbN688SMS4pD0+Tw4uX4dXJo7F+qXLANPG+aLjd5hB/39/amC7Hel0sxMNwRT7paPP4ZBXW0YVVMFL1cvSgEk6qOloQlBt1L0PglHj52C4yfOwMmTZ/cxWcE5FtYekIY1wvkLnXDh4hW4eKlr7MqVa2bs7d+L7FBTkwmZNevrCmRB1pw5UL9BFDoXzIdzCxaAP90QPL1CH3gHRfCzL//3UkijSREFhHz0EXSiAvpVaeBo6wEMc2fYvacaLd0BR49PgEZ6w6nT5ylLHzt++oCDi/eAhQ0TyjBIdl7pga6r1+Bqd99Yb/8NS/b270XKNTVnRyxc2JrCxQVFPNxQxM0FV5YuBtKrjBSRgE1eYWM+gVsD36hE3kGjCQUh+EBUQjOWll2KimBm6kgpoBID4FTQSG84/8VlytKXO7vB0cUbLFEBBxvaoKf3Olzru4H/3jNWW9fsz97+vUm6pCQrbObM5zuRBTl4aOrG4og0aAuFRMHbOxwDeFjtG50W28LDVwR+/PHzAFRA6bq1cEVBHkyMbMEIlbC3+iCcPXfxJehLl6++tDSJ+BY2HmBpy4TWwx1w9vxl6pygY2QPdB3L83goeq89/jw1NdHwWbO+LUXGZq9ZA13CgtCDabFxgziwNgaDb9C2/rS0/N/vLEeJiHy6benSvxMFpHByQh9WWuaG1mDIsIe9mP4mQV+ZoPdLS++pqEWWuICZlRv4BGwDKUU9WC+lDqLSGiCvanTPOyjuzXzwHeXsrl1zoxctupIrLfVjOj//2GURIaqDdVFWFnxYweAfHP1TXFKmGvvyfy2k1o7j4yOchRCsBrsszMFO3wL0kAUVVQdeAd1/fRCu3xiGAVy5BaXIEidKCQYmTiAmqwXictogqaALsioGP9o4sN6tNn8LyZGXT82Tl9+UxLHy0SVhIaqDNUBTgcDNIaiAmLGI6GQn9qX/XqJ5eOJ8UQG+mA6bMQu465qBjoE11bPr678J1weG4MbNERgcuoX07wNyNNbStwEDZImxmRNY2HqClJIeyKgYgBzNEBToxmNWDhsT2du/N6nBVLeLThdM4+S43ym0huPIDeNROcwvAkLCE0jHagvC+v1AmEWjMXwwEHrj1QXiYuBrYgtaelYQvjWJAj08cgetPoKHn2rQ0LcGcXltpLkhxRISKxzcfAhoUFRngJKGCahomYG2kd05Zmjoe29j58nKCufwrnrcgwq4wcUBN4TWnPNw9e0kbbv4lJxiwnD2pf9adtna8gQvmP/ICxUQjrl0i6kNaOpaghvTHy0/ijm+C1g+4YTabEvrU4B1DW1A39gO3DwDQVXHApc50PF36qgkHYb9E7+gbYrsW7w3SeXlFS1cueLbAfbE6aaMZCuT6d9F+pUxidv3v5ECOmi0j4MXLGgkCvDCg1GMgQlo6ViCmYUbFO2qBH0TBwo0obc8sbQaA5Q1TUEb3YS4iiszALRREZqGyBwjOwTvAHqmjuMOrt6ZGRkZCwODY1MSE/Ok2bebVtmjp+1QycXxy81V3NSY7bqy/A5v77C++ORsZMCO9jduyiTLyHiyZswY24hKYHJwgxbSmCjBY1MwKKi9Sm9ibTW0tJa+FWijq1jZeYIppkQEDYYYE4wtXMDEyhUwDnzPZIX2Orr6jm+NTL2I54q17NtNi5Bp9Q4RobR23lUwyMcDw4L8z646OnqFhifcptp2WYXHsRh6MwXkaWlxec2c9dB//vyvmDTN/eqa5uNqGmZg5+SFlLYCmvav9NZE6qOPIwMmXMXYzJk6OTIsXcHU2g2DogelFGuHjWDv7AX2Tt4US9IyCy8mJWW+c5/wdSml0WYWcHGeuIrgSSdrZJ3wtTyWr1V0XPovGdlFkJlTXIMKeLOuMfGVVCWliDwzM1F7Z28FVMBPquqmYGnNBGvHTRS9CWiK3iYTljZA19DQtgAtVMJm3/CXoG0dWQh8Mzi6eoMTBkg8LoO1PQuCw+LGI2PT2ouKKlawb/uHpEJHR66Ri+PJ4GpeYv2x25pqSV5eIV6JqTljpH1XUFy+841iwOsSFZU9T9/A7jaNbgJq6ubA3Bz6Kr3ZljbFIkiDuAMyxY0ZiFb2p0A7u/uCi4cfBscA8GAFoRJ8sWL0BDtURGxC1nj4tuSjuaWly9m3eychlq0WFszt5eOmhqq3pMX77/ix+LZFp1XlFk6073aX18S+0XngdSFawwC4XUWVASo0BniyQijLmiFoc1L+2iEr8G8btLQ+lr6EKabmbhAYGvMSNBNjx0avUGB5h1HLxmETmFq6Ud9j4lEJkcltSZn57+wOHWZmUp1CAo+pFp7khh/vONgab41NFk7JyL9TvHsv7CzdN4aHNCYZ4LJ/8nbCYoVpIfhxMrLS0rYGb/+tv0FvXyDHYVU2U0hfYBIwcQnyG1Im+wVFAZ7RqSYLOWRFYI6Oic8ci4rL7MzKLZF9Wyvd9ffkGFGQOTYqLADXpcXHO5wcijpKS2fmFJT5Ivh/lGKZXlp14LucvFLvqKikd1NyYGDgbF09ux5FJSNQUjYGb9+taF1/it6uzAl6u7MCqU9NbStQVmGAo5MPVYH5BkZSoANCYpAVsRC8JZ76d2d3P6weHSglpKTnQ2xiNllfb88rcSsvL//dLjIUFX3y0NZW466y3NUheWlokpUai6UpNwaamCxtOnaMY0/VgS/K8QRbgYc4zDidadsL/CMi4t6uRTYpxCq2tqwQVMC4gqIhGBo5QggCeZ3exNKEBURJGppWEB2bCWSQQkC/OjZPpb6T0yMpoPCsAFnZO6m5Iq6fMWpXl+2tFf2toAUffPBhrIWFZL6JcUaFpvoPCXhq3Sgg8MxOUDA3CsG3tp5esq/20L7KmoYX+2obJ/uWJQlJ230rWlvnsbd5e3F13cRDUzW5I69gAEQJPn6RSOmtU+g9YelNWCXS6KbUNa5uAdQLEQQ0eUliYpj660sShAmGmD00scZwdvXFQ1UZNWbLyC4ez84teVi4qyqxoqJGcEoB82EAjWZgMHfeI7UZM8Z15sz5gbFyZctGZWW1moyaWY2tR6WrDza17atrekGatQcaWuFAY9vfD9S3WBUUVWxCQ777dGoiGHrEycnrj8vK6YGmliVEYYn5Or2Jpa3tWIDXUUEzPnEH9a4AmSAT0PGTo3P2QJUESy1dK6CT7OEegNVmFTV8IdE7v7gCCkuq/l5aXltTua/eoaqsStJdQiLcXkgoPlBHh7knOUu4/vAprkPNh3XqGtp21dQ3PyGgSbOWtOVJC6+59fjh/OJytZKSvebvlAWmiqenP4eKqsktGVldIMudGUS9F/D6WyFBoXFAVzejrrGxZVFvhEyCJv4+ZYpMLW+/ragAc1BGhbl5BEFJ2X5q+LKzlJo4YQrDQFZRO44+/W3l/vq+qppDF/YdaPpi/8HmK2jp+wj6GQW6eQJ0U9sxaDl8gjRqnh7tOG2wv/aQzZEjp2XZMN5diAYtLNw3S8vojEtJayPNDSAKaU2UMJXexNpuHgEgK6dLMSE8IpnQ+p8GqjvySylLkykSUQK6GOU6RGklpfup4cu/nEW8ZulJ0IfbO6D96Ek4dvwUHDtxuqW1tYOzqelISG9v75u3x/+dbNoUNUdd0+KkpJQWkIXZgRqRx2EUn0pvMkcwNHakrqGrmUEmBjkC+BV64+GqqITk6WqSq4HMHkkAJczR1rGh3iFCK0+Axk9Cb9KWr5+YRVAd6pegjxHQp6l5xMlT50jj9uvW9hPqJ0+epZ87dzH0j06nXxEbm83ycvJ634hLaICEpCY4ufjC9pwS6s2QqfSOjE0HRSVDINeRd4B2oVXJeG0S9AS9f50vYuqi6gISO8i+hD0+ftugpq6ZzBgRdPuEpY9MtfSvoE+dmWjYHj12aqygaE8RFj7zLnV2RV7q7hZnP/r0iIWFxQxzS48QCUmt52Li6viwGuAfEE1ZduronPztFxhNsWCDmBq4ewTCnso6yqcnQU+dLxJL78e1I68EDAztqd+sF1XF2GAM26LSUAlHKdDHT0wBPaVLTZq21fsbxn18tzYmJGxfdvVqn11XV29kX1/fp+xHnz7BrPCphoZ5hZi4GohuoAOJCeQNL2LhSXqTMpT8TeIBAUOuJRbdW9OAPj0F9OSo7VAb26fbKUX4+EWADMYRYRElEBRWBClZHXBw9IZsZNs+/P3B+lZoOHQYag80QV5+GdjYsZ5hkN6bmpq7vKfvuk3vtYGb/f2D02v9qeLkFLQcy+OzxEpkoVtAYnIORevJ6E0sTRRhbbsR1q6nUYrwQ7bUkQcneXoKaDJuazlMxm0nyLgNrd0Be8r3I3MCYB3uzy8gB7z8MrAK12pBeRBeqwxCuPgEZMn3ETUNc/esrNL5CJrVf33ocf/AYOK0+v5viaurr6CiosE1Am7tOhWQltGG5NR88r4ARe/J6F1WWUt1lUTwgdeuo1HlNKH0lJRFTZ5I9J46eTp95gtcF6AeFRWH2YUoUg1TrLSczndKKsYDNDojV9/I1qKpqV1gYGCIPnBjpOXGzZFnNwdHzw4PD/85b5k7OW0Sw+LoJgFHrEJ8PiYuC2qRoi/p3dhGKcXabiNSGq/D5eTsAw2NR6hAdnximvwS9OQQ5osLnWTGSE2frnT1Uq353mvXob//Zn/f9cH66wPDDQM3ho/eHBy5Pzg4+oI0bXE9HR6+a/KHC5+3ETwdisvK6l4TQn8VElYCUTE6+PpHQWPLMSplTdK7rqEFmJ5BICikCAKCClhRWkEl5nsC+LdAT06fugnwKTMJMo+YbM8T0KOjd+HW7S/h9u0vxzu7eqsvXLjw7nX/uwqTGcSPqesEBqzxNYKKCFIJae8B1TWN1CR5kt7kcxumuw2YQfhWy2L8oENIWAL+39lXQff0vzqImTKToEDfukeBvnP3K7h37wH+213YX3OoOywscTX7kf58IS8vY0lbJLxW5ZnAGnlYjYucHeITsjF1Tbw3QCxN0tZuLH60dayBlw8DG580VQpnZhUjC678M+jB0d8A/RC+vP8I7n/1GH/TBdEx6Vft7b02sB/lPyeYImfq6dm7YXp8wL9aDsgSWKMAxgxnKMPscOHir/Q+eeo8hODZQWS9CnDySAA3rxRgcIOw8ERkzRlqCDMySe879ylLT4K+9+UjVGYnXps0Zmzq3Gzrwpq2JusfFhKAQkOjuBWUDKsEhZWeTlqZpDJDYyfYVbIPfb2LsjQZuR3vOAubvcNh3QZV4OASgxWcosCFChHHIsvZ1R9iYrOA9Ax25OzGLJMHXj4RgHuP4fU3NLWtfYjS2bf+awkZjRsa2mvKyus18q+R+4VYmHuVJPDgpwrdFIKC47CgacPo3g9Dw7fRopchFUtqQ4YTVfws5xCFJcvXvlwrOTeMcfNKPl6/QfWoEo3BSkjIXsK+1V9bSktLZ1paeirKKxpUrBFS+I6TWxw4yEJrk0BIqjzSTI3F9FlaVgM1tc3oLrWQll4AXt4RpFcwYuvgZaGmZiLh4xPKjYqd/vL2T5IPAwPTZhsbO7lJymhWrhej30KL/oiKeEFov2zl+lcWYQAy54a7u58y+/f/v4Q0QC0s3CWRzgYyMnoOBgzHWCOG4y48Shdr61pvkZLVtEYX4mVf/l+Zfvngg/8FzXHZ9OzWWpAAAAAASUVORK5CYII='
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()

# This is the icon in the upper left hand corner of the app
$form.Icon = $bitmap
# This is the toolbar icon and description
$form.TaskbarItemInfo.Overlay = $bitmap
$form.TaskbarItemInfo.Description = "WIM Witch - $wwscirptver"
###################################################

#endregion XAML

#region Functions
Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) { Write-Host 'If you need to reference this display again, run Get-FormVariables' -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    #write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    Get-Variable WPF*
}

#Get-FormVariables

#===========================================================================
# Functions for Controls
#===========================================================================

#Funtion to select mounting directory
Function Select-MountDir {

    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Select the mount folder'
    $null = $browser.ShowDialog()
    $MountDir = $browser.SelectedPath
    $WPFMISMountTextBox.text = $MountDir
    Test-MountPath -path $WPFMISMountTextBox.text
    Update-Log -Data 'Mount directory selected' -Class Information
}

#Function to select Source WIM
Function Select-SourceWIM {

    $SourceWIM = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        #InitialDirectory = [Environment]::GetFolderPath('Desktop')
        InitialDirectory = "$PSScriptRoot\imports\wim"
        Filter           = 'WIM (*.wim)|'
    }
    $null = $SourceWIM.ShowDialog()
    $WPFSourceWIMSelectWIMTextBox.text = $SourceWIM.FileName


    if ($SourceWIM.FileName -notlike '*.wim') {
        Update-Log -Data 'A WIM file not selected. Please select a valid file to continue.' -Class Warning
        return
    }


    #Select the index
    $ImageFull = @(Get-WindowsImage -ImagePath $WPFSourceWIMSelectWIMTextBox.text)
    $a = $ImageFull | Out-GridView -Title 'Choose an Image Index' -PassThru
    $IndexNumber = $a.ImageIndex
    #write-host $IndexNumber
    if ($null -eq $indexnumber) {
        Update-Log -Data 'Index not selected. Reselect the WIM file to select an index' -Class Warning
        return
    }

    Import-WimInfo -IndexNumber $IndexNumber
}

Function Import-WimInfo($IndexNumber, [switch]$SkipUserConfirmation) {
    Update-Log -Data 'Importing Source WIM Info' -Class Information
    try {
        #Gets WIM metadata to populate fields on the Source tab.
        $ImageInfo = Get-WindowsImage -ImagePath $WPFSourceWIMSelectWIMTextBox.text -Index $IndexNumber -ErrorAction Stop
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data 'The WIM file selected may be borked. Try a different one' -Class Warning
        Return
    }
    $text = 'WIM file selected: ' + $SourceWIM.FileName
    # $text = "WIM file selected: " + $ImageInfo.FileName
    Update-Log -data $text -Class Information
    $text = 'Edition selected: ' + $ImageInfo.ImageName

    Update-Log -data $text -Class Information
    $ImageIndex = $IndexNumber

    $WPFSourceWIMImgDesTextBox.text = $ImageInfo.ImageName
    $WPFSourceWimVerTextBox.Text = $ImageInfo.Version
    $WPFSourceWimSPBuildTextBox.text = $ImageInfo.SPBuild
    $WPFSourceWimLangTextBox.text = $ImageInfo.Languages
    $WPFSourceWimIndexTextBox.text = $ImageIndex
    if ($ImageInfo.Architecture -eq 9) {
        $WPFSourceWimArchTextBox.text = 'x64'
    }
    Else {
        $WPFSourceWimArchTextBox.text = 'x86'
    }
    if ($WPFSourceWIMImgDesTextBox.text -like 'Windows Server*') {
        $WPFJSONEnableCheckBox.IsChecked = $False
        $WPFAppxCheckBox.IsChecked = $False
        $WPFAppTab.IsEnabled = $False
        $WPFAutopilotTab.IsEnabled = $False
        $WPFMISAppxTextBox.text = 'False'
        $WPFMISJSONTextBox.text = 'False'
        $WPFMISOneDriveCheckBox.IsChecked = $False
        $WPFMISOneDriveCheckBox.IsEnabled = $False
    }
    Else {
        $WPFAppTab.IsEnabled = $True
        $WPFAutopilotTab.IsEnabled = $True
        $WPFMISOneDriveCheckBox.IsEnabled = $True
    }

    ######right here
    if ($SkipUserConfirmation -eq $False) { $WPFSourceWimTBVersionNum.text = Get-WinVersionNumber }
}

#Function to Select JSON File
Function Select-JSONFile {

    $JSON = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'JSON (*.JSON)|'
    }
    $null = $JSON.ShowDialog()
    $WPFJSONTextBox.Text = $JSON.FileName

    $text = 'JSON file selected: ' + $JSON.FileName
    Update-Log -Data $text -Class Information
    Invoke-ParseJSON -file $JSON.FileName
}

#Function to parse the JSON file for user valuable info
Function Invoke-ParseJSON($file) {
    try {
        Update-Log -Data 'Attempting to parse JSON file...' -Class Information
        $autopilotinfo = Get-Content $WPFJSONTextBox.Text | ConvertFrom-Json
        Update-Log -Data 'Successfully parsed JSON file' -Class Information
        $WPFZtdCorrelationId.Text = $autopilotinfo.ZtdCorrelationId
        $WPFCloudAssignedTenantDomain.Text = $autopilotinfo.CloudAssignedTenantDomain
        $WPFComment_File.text = $autopilotinfo.Comment_File

    }
    catch {
        $WPFZtdCorrelationId.Text = 'Bad file. Try Again.'
        $WPFCloudAssignedTenantDomain.Text = 'Bad file. Try Again.'
        $WPFComment_File.text = 'Bad file. Try Again.'
        Update-Log -Data 'Failed to parse JSON file. Try another'
        return
    }
}

#Function to select the paths for the driver fields
Function Select-DriverSource($DriverTextBoxNumber) {
    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Select the Driver Source folder'
    $null = $browser.ShowDialog()
    $DriverDir = $browser.SelectedPath
    $DriverTextBoxNumber.Text = $DriverDir
    Update-Log -Data "Driver path selected: $DriverDir" -Class Information
}

#Function for the Make it So button
Function Invoke-MakeItSo ($appx) {
    #Check if new file name is valid, also append file extension if neccessary

    ###Starting MIS Preflight###
    Test-MountPath -path $WPFMISMountTextBox.Text -clean True

    if (($WPFMISWimNameTextBox.Text -eq '') -or ($WPFMISWimNameTextBox.Text -eq 'Enter Target WIM Name')) {
        Update-Log -Data 'Enter a valid file name and then try again' -Class Error
        return
    }


    if (($auto -eq $false) -and ($WPFCMCBImageType.SelectedItem -ne 'Update Existing Image' )) {

        $checkresult = (Test-Name)
        if ($checkresult -eq 'stop') { return }
    }


    #check for working directory, make if does not exist, delete files if they exist
    Update-Log -Data 'Checking to see if the staging path exists...' -Class Information

    try {
        if (!(Test-Path "$PSScriptRoot\Staging" -PathType 'Any')) {
            New-Item -ItemType Directory -Force -Path $PSScriptRoot\Staging -ErrorAction Stop
            Update-Log -Data 'Path did not exist, but it does now' -Class Information -ErrorAction Stop
        }
        Else {
            Remove-Item –Path $PSScriptRoot\Staging\* -Recurse -ErrorAction Stop
            Update-Log -Data 'The path existed, and it has been purged.' -Class Information -ErrorAction Stop
        }
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "Something is wrong with folder $PSScriptRoot\Staging. Try deleting manually if it exists" -Class Error
        return
    }

    if ($WPFJSONEnableCheckBox.IsChecked -eq $true) {
        Update-Log -Data 'Validating existance of JSON file...' -Class Information
        $APJSONExists = (Test-Path $WPFJSONTextBox.Text)
        if ($APJSONExists -eq $true) { Update-Log -Data 'JSON exists. Continuing...' -Class Information }
        else {
            Update-Log -Data 'The Autopilot file could not be verified. Check it and try again.' -Class Error
            return
        }

    }

    if ($WPFMISDotNetCheckBox.IsChecked -eq $true) {
        if ((Test-DotNetExists) -eq $False) { return }
    }


    #Check for free space
    if ($SkipFreeSpaceCheck -eq $false) {
        if (Test-FreeSpace -eq 1) {
            Update-Log -Data 'Insufficient free space. Delete some files and try again' -Class Error
            return
        }
        else {
            Update-Log -Data 'There is sufficient free space.' -Class Information
        }
    }
    #####End of MIS Preflight###################################################################

    #Copy source WIM
    Update-Log -Data 'Copying source WIM to the staging folder' -Class Information

    try {
        Copy-Item $WPFSourceWIMSelectWIMTextBox.Text -Destination "$PSScriptRoot\Staging" -ErrorAction Stop
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -Data "The file couldn't be copied. No idea what happened" -class Error
        return
    }

    Update-Log -Data 'Source WIM has been copied to the source folder' -Class Information

    #Rename copied source WiM

    try {
        $wimname = Get-Item -Path $PSScriptRoot\Staging\*.wim -ErrorAction Stop
        Rename-Item -Path $wimname -NewName $WPFMISWimNameTextBox.Text -ErrorAction Stop
        Update-Log -Data 'Copied source WIM has been renamed' -Class Information
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "The copied source file couldn't be renamed. This shouldn't have happened." -Class Error
        Update-Log -data "Go delete the WIM from $PSScriptRoot\Staging\, then try again" -Class Error
        return
    }

    #Remove the unwanted indexes
    Remove-OSIndex

    #Mount the WIM File
    $wimname = Get-Item -Path $PSScriptRoot\Staging\*.wim
    Update-Log -Data "Mounting source WIM $wimname" -Class Information
    Update-Log -Data 'to mount point:' -Class Information
    Update-Log -data $WPFMISMountTextBox.Text -Class Information

    try {
        Mount-WindowsImage -Path $WPFMISMountTextBox.Text -ImagePath $wimname -Index 1 -ErrorAction Stop | Out-Null
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "The WIM couldn't be mounted. Make sure the mount directory is empty" -Class Error
        Update-Log -Data "and that it isn't an active mount point" -Class Error
        return
    }

    #checks to see if the iso binaries exist. Cancel and discard WIM if they are not present.
    If (($WPFMISCBISO.IsChecked -eq $true) -or ($WPFMISCBUpgradePackage.IsChecked -eq $true)) {

        if ((Test-IsoBinariesExist) -eq $False) {
            Update-Log -Data 'Discarding WIM and not making it so' -Class Error
            Dismount-WindowsImage -Path $WPFMISMountTextBox.Text -Discard -ErrorAction Stop | Out-Null
            return
        }
    }

    #Get Mounted WIM version and save it to a variable for useage later in the Function
    $MISWinVer = (Get-WinVersionNumber)


    #Pause after mounting
    If ($WPFMISCBPauseMount.IsChecked -eq $True) {
        Update-Log -Data 'Pausing image building. Waiting on user to continue...' -Class Warning
        $Pause = Suspend-MakeItSo
        if ($Pause -eq 'Yes') { Update-Log -data 'Continuing on with making it so...' -Class Information }
        if ($Pause -eq 'No') {
            Update-Log -data 'Discarding build...' -Class Error
            Update-Log -Data 'Discarding mounted WIM' -Class Warning
            Dismount-WindowsImage -Path $WPFMISMountTextBox.Text -Discard -ErrorAction Stop | Out-Null
            Update-Log -Data 'WIM has been discarded. Better luck next time.' -Class Warning
            return
        }
    }

    #Run Script after mounting
    if (($WPFCustomCBRunScript.IsChecked -eq $True) -and ($WPFCustomCBScriptTiming.SelectedItem -eq 'After image mount')) {
        Update-Log -data 'Running PowerShell script...' -Class Information
        Start-Script -file $WPFCustomTBFile.text -parameter $WPFCustomTBParameters.text
        Update-Log -data 'Script completed.' -Class Information
    }

    #Language Packs and FOD
    if ($WPFCustomCBLangPacks.IsChecked -eq $true) {
        Install-LanguagePacks
    }
    else {
        Update-Log -Data 'Language Packs Injection not selected. Skipping...'
    }

    if ($WPFCustomCBLEP.IsChecked -eq $true) {
        Install-LocalExperiencePack
    }
    else {
        Update-Log -Data 'Local Experience Packs not selected. Skipping...'
    }

    if ($WPFCustomCBFOD.IsChecked -eq $true) {
        Install-FeaturesOnDemand
    }
    else {
        Update-Log -Data 'Features On Demand not selected. Skipping...'
    }

    #Inject .Net Binaries
    if ($WPFMISDotNetCheckBox.IsChecked -eq $true) { Add-DotNet }

    #Inject Autopilot JSON file
    if ($WPFJSONEnableCheckBox.IsChecked -eq $true) {
        Update-Log -Data 'Injecting JSON file' -Class Information
        try {
            $autopilotdir = $WPFMISMountTextBox.Text + '\windows\Provisioning\Autopilot'
            Copy-Item $WPFJSONTextBox.Text -Destination $autopilotdir -ErrorAction Stop
        }
        catch {
            Update-Log -data $_.Exception.Message -class Error
            Update-Log -data "JSON file couldn't be copied. Check to see if the correct SKU" -Class Error
            Update-Log -Data 'of Windows has been selected' -Class Error
            Update-log -Data "The WIM is still mounted. You'll need to clean that up manually until" -Class Error
            Update-Log -data 'I get around to handling that error more betterer' -Class Error
            return
        }
    }
    else {
        Update-Log -Data 'JSON not selected. Skipping JSON Injection' -Class Information
    }

    #Inject Drivers
    If ($WPFDriverCheckBox.IsChecked -eq $true) {
        Start-DriverInjection -Folder $WPFDriverDir1TextBox.text
        Start-DriverInjection -Folder $WPFDriverDir2TextBox.text
        Start-DriverInjection -Folder $WPFDriverDir3TextBox.text
        Start-DriverInjection -Folder $WPFDriverDir4TextBox.text
        Start-DriverInjection -Folder $WPFDriverDir5TextBox.text
    }
    Else {
        Update-Log -Data 'Drivers were not selected for injection. Skipping.' -Class Information
    }

    #Inject default application association XML
    if ($WPFCustomCBEnableApp.IsChecked -eq $true) {
        Install-DefaultApplicationAssociations
    }
    else {
        Update-Log -Data 'Default Application Association not selected. Skipping...' -Class Information
    }

    #Inject start menu layout
    if ($WPFCustomCBEnableStart.IsChecked -eq $true) {
        Install-StartLayout
    }
    else {
        Update-Log -Data 'Start Menu Layout injection not selected. Skipping...' -Class Information
    }

    #apply registry files
    if ($WPFCustomCBEnableRegistry.IsChecked -eq $true) {
        Install-RegistryFiles
    }
    else {
        Update-Log -Data 'Registry file injection not selected. Skipping...' -Class Information
    }

    #Check for updates when ConfigMgr source is selected
    if ($WPFMISCBCheckForUpdates.IsChecked -eq $true) {
        Invoke-MISUpdates
        if (($WPFSourceWIMImgDesTextBox.text -like '*Windows 10*') -or ($WPFSourceWIMImgDesTextBox.text -like '*Windows 11*')) { Get-OneDrive }
    }

    #Apply Updates
    If ($WPFUpdatesEnableCheckBox.IsChecked -eq $true) {
        Deploy-Updates -class 'SSU'
        Deploy-Updates -class 'LCU'
        Deploy-Updates -class 'AdobeSU'
        Deploy-Updates -class 'DotNet'
        Deploy-Updates -class 'DotNetCU'
        #if ($WPFUpdatesCBEnableDynamic.IsChecked -eq $True){Deploy-Updates -class "Dynamic"}
        if ($WPFUpdatesOptionalEnableCheckBox.IsChecked -eq $True) {
            Deploy-Updates -class 'Optional'
        }
    }
    else {
        Update-Log -Data 'Updates not enabled' -Class Information
    }

    #Copy the current OneDrive installer
    if ($WPFMISOneDriveCheckBox.IsChecked -eq $true) {
        $os = Get-WindowsType
        $build = Get-WinVersionNumber

        if (($os -eq 'Windows 11') -and ($build -eq '22H2')) {
            Copy-OneDrivex64
        }
        else {
            Copy-OneDrive
        }
    }
    else {
        Update-Log -data 'OneDrive agent update skipped as it was not selected' -Class Information
    }

    #Remove AppX Packages
    if ($WPFAppxCheckBox.IsChecked -eq $true) {
        Remove-Appx -array $appx
    }
    Else {
        Update-Log -Data 'App removal not enabled' -Class Information
    }

    #Run Script before dismount
    if (($WPFCustomCBRunScript.IsChecked -eq $True) -and ($WPFCustomCBScriptTiming.SelectedItem -eq 'Before image dismount')) {
        Start-Script -file $WPFCustomTBFile.text -parameter $WPFCustomTBParameters.text
    }

    #Pause before dismounting
    If ($WPFMISCBPauseDismount.IsChecked -eq $True) {
        Update-Log -Data 'Pausing image building. Waiting on user to continue...' -Class Warning
        $Pause = Suspend-MakeItSo
        if ($Pause -eq 'Yes') { Update-Log -data 'Continuing on with making it so...' -Class Information }
        if ($Pause -eq 'No') {
            Update-Log -data 'Discarding build...' -Class Error
            Update-Log -Data 'Discarding mounted WIM' -Class Warning
            Dismount-WindowsImage -Path $WPFMISMountTextBox.Text -Discard -ErrorAction Stop | Out-Null
            Update-Log -Data 'WIM has been discarded. Better luck next time.' -Class Warning
            return
        }
    }

    #Copy log to mounted WIM
    try {
        Update-Log -Data 'Attempting to copy log to mounted image' -Class Information
        $mountlogdir = $WPFMISMountTextBox.Text + '\windows\'
        Copy-Item $PSScriptRoot\logging\WIMWitch.log -Destination $mountlogdir -ErrorAction Stop
        $CopyLogExist = Test-Path $mountlogdir\WIMWitch.log -PathType Leaf
        if ($CopyLogExist -eq $true) { Update-Log -Data 'Log filed copied successfully' -Class Information }
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "Coudn't copy the log file to the mounted image." -class Error
    }

    #Dismount, commit, and move WIM
    Update-Log -Data 'Dismounting WIM file, committing changes' -Class Information
    try {
        Dismount-WindowsImage -Path $WPFMISMountTextBox.Text -Save -ErrorAction Stop | Out-Null
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "The WIM couldn't save. You will have to manually discard the" -Class Error
        Update-Log -data 'mounted image manually' -Class Error
        return
    }
    Update-Log -Data 'WIM dismounted' -Class Information

    #Display new version number
    $WimInfo = (Get-WindowsImage -ImagePath $wimname -Index 1)
    $text = 'New image version number is ' + $WimInfo.Version
    Update-Log -data $text -Class Information

    if (($auto -eq $true) -or ($WPFCMCBImageType.SelectedItem -eq 'Update Existing Image')) {
        Update-Log -Data 'Backing up old WIM file...' -Class Information
        $checkresult = (Test-Name -conflict append)
        if ($checkresult -eq 'stop') { return }
    }

    #stage media if check boxes are selected
    if (($WPFMISCBUpgradePackage.IsChecked -eq $true) -or ($WPFMISCBISO.IsChecked -eq $true)) {
        Copy-StageIsoMedia
        Update-Log -Data 'Exporting install.wim to media staging folder...' -Class Information
        Export-WindowsImage -SourceImagePath $wimname -SourceIndex 1 -DestinationImagePath ($PSScriptRoot + '\staging\media\sources\install.wim') -DestinationName ('WW - ' + $WPFSourceWIMImgDesTextBox.text) | Out-Null
    }

    #Export the wim file to various locations
    if ($WPFMISCBNoWIM.IsChecked -ne $true) {
        try {
            Update-Log -Data 'Exporting WIM file' -Class Information
            Export-WindowsImage -SourceImagePath $wimname -SourceIndex 1 -DestinationImagePath ($WPFMISWimFolderTextBox.Text + '\' + $WPFMISWimNameTextBox.Text) -DestinationName ('WW - ' + $WPFSourceWIMImgDesTextBox.text) | Out-Null
        }
        catch {
            Update-Log -data $_.Exception.Message -class Error
            Update-Log -data "The WIM couldn't be exported. You can still retrieve it from staging path." -Class Error
            Update-Log -data 'The file will be deleted when the tool is rerun.' -Class Error
            return
        }
        Update-Log -Data 'WIM successfully exported to target folder' -Class Information
    }

    #ConfigMgr Integration
    if ($WPFCMCBImageType.SelectedItem -ne 'Disabled') {
        #  "New Image","Update Existing Image"
        if ($WPFCMCBImageType.SelectedItem -eq 'New Image') {
            Update-Log -data 'Creating a new image in ConfigMgr...' -class Information
            New-CMImagePackage
        }

        if ($WPFCMCBImageType.SelectedItem -eq 'Update Existing Image') {
            Update-Log -data 'Updating the existing image in ConfigMgr...' -class Information
            Update-CMImage
        }
    }

    #Apply Dynamic Update to media
    if ($WPFMISCBDynamicUpdates.IsChecked -eq $true) {
        Deploy-Updates -class 'Dynamic'
    }
    else {
        Update-Log -data 'Dynamic Updates skipped or not applicable' -Class Information
    }

    #Apply updates to the boot.wim file
    if ($WPFMISCBBootWIM.IsChecked -eq $true) {
        Update-BootWIM
    }
    else {
        Update-Log -data 'Updating Boot.WIM skipped or not applicable' -Class Information
    }

    #Copy upgrade package binaries if selected
    if ($WPFMISCBUpgradePackage.IsChecked -eq $true) {
        Copy-UpgradePackage
    }
    else {
        Update-Log -Data 'Upgrade Package skipped or not applicable' -Class Information
    }

    #Create ISO if selected
    if ($WPFMISCBISO.IsChecked -eq $true) {
        New-WindowsISO
    }
    else {
        Update-Log -Data 'ISO Creation skipped or not applicable' -Class Information
    }

    #Run Script when build complete
    if (($WPFCustomCBRunScript.IsChecked -eq $True) -and ($WPFCustomCBScriptTiming.SelectedItem -eq 'On build completion')) {
        Start-Script -file $WPFCustomTBFile.text -parameter $WPFCustomTBParameters.text
    }

    #Clear out staging folder
    try {
        Update-Log -Data 'Clearing staging folder...' -Class Information
        Remove-Item $PSScriptRoot\staging\* -Force -Recurse -ErrorAction Stop
    }
    catch {
        Update-Log -Data 'Could not clear staging folder' -Class Warning
        Update-Log -data $_.Exception.Message -class Error
    }

    #Copy log here
    try {
        Update-Log -Data 'Copying build log to target folder' -Class Information
        Copy-Item -Path $PSScriptRoot\logging\WIMWitch.log -Destination $WPFMISWimFolderTextBox.Text -ErrorAction Stop
        $logold = $WPFMISWimFolderTextBox.Text + '\WIMWitch.log'
        $lognew = $WPFMISWimFolderTextBox.Text + '\' + $WPFMISWimNameTextBox.Text + '.log'
        #Put log detection code here
        if ((Test-Path -Path $lognew) -eq $true) {
            Update-Log -Data 'A preexisting log file contains the same name. Renaming old log...' -Class Warning
            Rename-Name -file $lognew -extension '.log'
        }

        #Put log detection code here
        Rename-Item $logold -NewName $lognew -Force -ErrorAction Stop
        Update-Log -Data 'Log copied successfully' -Class Information
    }
    catch {
        Update-Log -data $_.Exception.Message -class Error
        Update-Log -data "The log file couldn't be copied and renamed. You can still snag it from the source." -Class Error
        Update-Log -Data "Job's done." -Class Information
        return
    }
    Update-Log -Data "Job's done." -Class Information
}

#Function to assign the target directory
Function Select-TargetDir {
    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Select the target folder'
    $null = $browser.ShowDialog()
    $TargetDir = $browser.SelectedPath
    $WPFMISWimFolderTextBox.text = $TargetDir #I SCREWED UP THIS VARIABLE
    Update-Log -Data 'Target directory selected' -Class Information
}

#Function to enable logging and folder check
Function Update-Log {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string]$Data,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string]$Solution = $Solution,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1
        )]
        [validateset('Information', 'Warning', 'Error', 'Comment')]
        [string]$Class = 'Information'

    )

    $global:ScriptLogFilePath = $Log
    $LogString = "$(Get-Date) $Class  -  $Data"
    $HostString = "$(Get-Date) $Class  -  $Data"


    Add-Content -Path $Log -Value $LogString
    switch ($Class) {
        'Information' {
            Write-Host $HostString -ForegroundColor Gray
        }
        'Warning' {
            Write-Host $HostString -ForegroundColor Yellow
        }
        'Error' {
            Write-Host $HostString -ForegroundColor Red
        }
        'Comment' {
            Write-Host $HostString -ForegroundColor Green
        }

        Default { }
    }
    #The below line is for a logging tab that was removed. If it gets put back in, reenable the line
    #  $WPFLoggingTextBox.text = Get-Content -Path $Log -Delimiter "\n"
}

#Removes old log and creates all folders if does not exist
Function Set-Logging {
    #logging folder
    if (!(Test-Path -Path $PSScriptRoot\logging\WIMWitch.Log -PathType Leaf)) {
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\Logging | Out-Null
        New-Item -Path $PSScriptRoot\logging -Name 'WIMWitch.log' -ItemType 'file' -Value '***Logging Started***' | Out-Null
    }
    Else {
        Remove-Item -Path $PSScriptRoot\logging\WIMWitch.log
        New-Item -Path $PSScriptRoot\logging -Name 'WIMWitch.log' -ItemType 'file' -Value '***Logging Started***' | Out-Null
    }


    #updates folder
    $FileExist = Test-Path -Path $PSScriptRoot\updates #-PathType Leaf
    if ($FileExist -eq $False) {
        Update-Log -Data 'Updates folder does not exist. Creating...' -Class Warning
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\updates | Out-Null
        Update-Log -Data 'Updates folder created' -Class Information
    }

    if ($FileExist -eq $True) { Update-Log -Data 'Updates folder exists' -Class Information }

    #staging folder
    $FileExist = Test-Path -Path $PSScriptRoot\Staging #-PathType Leaf
    if ($FileExist -eq $False) {
        Update-Log -Data 'Staging folder does not exist. Creating...' -Class Warning
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\Staging | Out-Null
        Update-Log -Data 'Staging folder created' -Class Information
    }

    if ($FileExist -eq $True) { Update-Log -Data 'Staging folder exists' -Class Information }

    #Mount folder
    $FileExist = Test-Path -Path $PSScriptRoot\Mount #-PathType Leaf
    if ($FileExist -eq $False) {
        Update-Log -Data 'Mount folder does not exist. Creating...' -Class Warning
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\Mount | Out-Null
        Update-Log -Data 'Mount folder created' -Class Information
    }

    if ($FileExist -eq $True) { Update-Log -Data 'Mount folder exists' -Class Information }

    #Completed WIMs folder
    $FileExist = Test-Path -Path $PSScriptRoot\CompletedWIMs #-PathType Leaf
    if ($FileExist -eq $False) {
        Update-Log -Data 'CompletedWIMs folder does not exist. Creating...' -Class Warning
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\CompletedWIMs | Out-Null
        Update-Log -Data 'CompletedWIMs folder created' -Class Information
    }

    if ($FileExist -eq $True) { Update-Log -Data 'CompletedWIMs folder exists' -Class Information }

    #Configurations XML folder
    $FileExist = Test-Path -Path $PSScriptRoot\Configs #-PathType Leaf
    if ($FileExist -eq $False) {
        Update-Log -Data 'Configs folder does not exist. Creating...' -Class Warning
        New-Item -ItemType Directory -Force -Path $PSScriptRoot\Configs | Out-Null
        Update-Log -Data 'Configs folder created' -Class Information
    }

    if ($FileExist -eq $True) { Update-Log -Data 'Configs folder exists' -Class Information }

}

Function Install-Driver($drivertoapply) {
    try {
        Add-WindowsDriver -Path $WPFMISMountTextBox.Text -Driver $drivertoapply -ErrorAction Stop | Out-Null
        Update-Log -Data "Applied $drivertoapply" -Class Information
    }
    catch {
        Update-Log -Data "Couldn't apply $drivertoapply" -Class Warning
    }

}

#Function for injecting drivers into the mounted WIM
Function Start-DriverInjection($Folder) {
    #This filters out invalid paths, such as the default value
    $testpath = Test-Path $folder -PathType Container
    If ($testpath -eq $false) { return }

    If ($testpath -eq $true) {

        Update-Log -data "Applying drivers from $folder" -class Information

        Get-ChildItem $Folder -Recurse -Filter '*inf' | ForEach-Object { Install-Driver $_.FullName }
        Update-Log -Data "Completed driver injection from $folder" -Class Information
    }
}

#Function to retrieve OSDUpdate Version
Function Get-OSDBInstallation {
    Update-Log -Data 'Getting OSD Installation information' -Class Information
    try {
        Import-Module -Name OSDUpdate -ErrorAction Stop
    }
    catch {
        $WPFUpdatesOSDBVersion.Text = 'Not Installed.'
        Update-Log -Data 'OSD Update is not installed.' -Class Warning
        Return
    }
    try {
        $OSDBVersion = Get-Module -Name OSDUpdate -ErrorAction Stop
        $WPFUpdatesOSDBVersion.Text = $OSDBVersion.Version
        $text = $osdbversion.version
        Update-Log -data "Installed version of OSD Update is $text." -Class Information
        Return
    }
    catch {
        Update-Log -Data 'Unable to fetch OSD Update version.' -Class Error
        Return
    }
}

# Function to retrieve OSDSUS Version

Function Get-OSDSUSInstallation {
    Update-Log -Data 'Getting OSDSUS Installation information' -Class 'Information'
    try {
        Import-Module -Name OSDSUS -ErrorAction Stop
    }
    catch {
        $WPFUpdatesOSDSUSVersion.Text = 'Not Installed'
        Update-Log -Data 'OSDSUS is not installed.' -Class Warning
        Return
    }
    try {
        $OSDSUSVersion = Get-Module -Name OSDSUS -ErrorAction Stop
        $WPFUpdatesOSDSUSVersion.Text = $OSDSUSVersion.Version
        $text = $osdsusversion.version
        Update-Log -data "Installed version of OSDSUS is $text." -Class Information
        Return
    }
    catch {
        Update-Log -Data 'Unable to fetch OSDSUS version.' -Class Error
        Return
    }
}

#Function to retrieve current OSDUpdate Version
Function Get-OSDBCurrentVer {
    Update-Log -Data 'Checking for the most current OSDUpdate version available' -Class Information
    try {
        $OSDBCurrentVer = Find-Module -Name OSDUpdate -ErrorAction Stop
        $WPFUpdatesOSDBCurrentVerTextBox.Text = $OSDBCurrentVer.version
        $text = $OSDBCurrentVer.version
        Update-Log -data "$text is the most current version" -class Information
        Return
    }
    catch {
        $WPFUpdatesOSDBCurrentVerTextBox.Text = 'Network Error'
        Return
    }
}

#Function to retrieve current OSDUSUS Version
Function Get-OSDSUSCurrentVer {
    Update-Log -Data 'Checking for the most current OSDSUS version available' -Class Information
    try {
        $OSDSUSCurrentVer = Find-Module -Name OSDSUS -ErrorAction Stop
        $WPFUpdatesOSDSUSCurrentVerTextBox.Text = $OSDSUSCurrentVer.version
        $text = $OSDSUSCurrentVer.version
        Update-Log -data "$text is the most current version" -class Information
        Return
    }
    catch {
        $WPFUpdatesOSDSUSCurrentVerTextBox.Text = 'Network Error'
        Return
    }
}

#Function to update or install OSDUpdate
Function Update-OSDB {
    if ($WPFUpdatesOSDBVersion.Text -eq 'Not Installed') {
        Update-Log -Data 'Attempting to install and import OSD Update' -Class Information
        try {
            Install-Module OSDUpdate -Force -ErrorAction Stop
            #Write-Host "Installed module"
            Update-Log -data 'OSD Update module has been installed' -Class Information
            Import-Module -Name OSDUpdate -Force -ErrorAction Stop
            #Write-Host "Imported module"
            Update-Log -Data 'OSD Update module has been imported' -Class Information
            Update-Log -Data '****************************************************************************' -Class Warning
            Update-Log -Data 'Please close WIM Witch and all PowerShell windows, then rerun to continue...' -Class Warning
            Update-Log -Data '****************************************************************************' -Class Warning
            #$WPFUpdatesOSDBClosePowerShellTextBlock.visibility = "Visible"
            $WPFUpdatesOSDListBox.items.add('Please close all PowerShell windows, including WIM Witch, then relaunch app to continue')
            Return
        }
        catch {
            $WPFUpdatesOSDBVersion.Text = 'Inst Fail'
            Update-Log -Data "Couldn't install OSD Update" -Class Error
            Update-Log -data $_.Exception.Message -class Error
            Return
        }
    }

    If ($WPFUpdatesOSDBVersion.Text -gt '1.0.0') {
        Update-Log -data 'Attempting to update OSD Update' -class Information
        try {
            Update-ModuleOSDUpdate -ErrorAction Stop
            Update-Log -Data 'Updated OSD Update' -Class Information
            Update-Log -Data '****************************************************************************' -Class Warning
            Update-Log -Data 'Please close WIM Witch and all PowerShell windows, then rerun to continue...' -Class Warning
            Update-Log -Data '****************************************************************************' -Class Warning
            #$WPFUpdatesOSDBClosePowerShellTextBlock.visibility = "Visible"
            $WPFUpdatesOSDListBox.items.add('Please close all PowerShell windows, including WIM Witch, then relaunch app to continue')

            get-OSDBInstallation
            return
        }
        catch {
            $WPFUpdatesOSDBCurrentVerTextBox.Text = 'OSDB Err'
            Return
        }
    }
}

#Function to update or install OSDSUS
Function Update-OSDSUS {
    if ($WPFUpdatesOSDSUSVersion.Text -eq 'Not Installed') {
        Update-Log -Data 'Attempting to install and import OSDSUS' -Class Information
        try {
            Install-Module OSDUpdate -Force -ErrorAction Stop
            Update-Log -data 'OSDSUS module has been installed' -Class Information
            Import-Module -Name OSDUpdate -Force -ErrorAction Stop
            Update-Log -Data 'OSDSUS module has been imported' -Class Information
            Update-Log -Data '****************************************************************************' -Class Warning
            Update-Log -Data 'Please close WIM Witch and all PowerShell windows, then rerun to continue...' -Class Warning
            Update-Log -Data '****************************************************************************' -Class Warning
            #$WPFUpdatesOSDBClosePowerShellTextBlock.visibility = "Visible"
            $WPFUpdatesOSDListBox.items.add('Please close all PowerShell windows, including WIM Witch, then relaunch app to continue')
            Return
        }
        catch {
            $WPFUpdatesOSDSUSVersion.Text = 'Inst Fail'
            Update-Log -Data "Couldn't install OSDSUS" -Class Error
            Update-Log -data $_.Exception.Message -class Error
            Return
        }
    }

    If ($WPFUpdatesOSDSUSVersion.Text -gt '1.0.0') {
        Update-Log -data 'Attempting to update OSDSUS' -class Information
        try {
            Uninstall-Module -Name osdsus -AllVersions -Force
            Install-Module -Name osdsus -Force
            Update-Log -Data 'Updated OSDSUS' -Class Information
            Update-Log -Data '****************************************************************************' -Class Warning
            Update-Log -Data 'Please close WIM Witch and all PowerShell windows, then rerun to continue...' -Class Warning
            Update-Log -Data '****************************************************************************' -Class Warning
            #$WPFUpdatesOSDBClosePowerShellTextBlock.visibility = "Visible"
            $WPFUpdatesOSDListBox.items.add('Please close all PowerShell windows, including WIM Witch, then relaunch app to continue')
            get-OSDSUSInstallation
            return
        }
        catch {
            $WPFUpdatesOSDSUSCurrentVerTextBox.Text = 'OSDSUS Err'
            Return
        }
    }
}

#Function to compare OSDBuilder Versions
Function Compare-OSDBuilderVer {
    Update-Log -data 'Comparing OSD Update module versions' -Class Information
    if ($WPFUpdatesOSDBVersion.Text -eq 'Not Installed') {
        Return
    }
    If ($WPFUpdatesOSDBVersion.Text -eq $WPFUpdatesOSDBCurrentVerTextBox.Text) {
        Update-Log -Data 'OSD Update is up to date' -class Information
        Return
    }
    #$WPFUpdatesOSDBOutOfDateTextBlock.Visibility = "Visible"
    $WPFUpdatesOSDListBox.items.add('A software update module is out of date. Please click the Install / Update button to update it.')
    Update-Log -Data 'OSD Update appears to be out of date. Run the upgrade Function from within WIM Witch to resolve' -class Warning

    Return
}

#Function to compare OSDSUS Versions
Function Compare-OSDSUSVer {
    Update-Log -data 'Comparing OSDSUS module versions' -Class Information
    if ($WPFUpdatesOSDSUSVersion.Text -eq 'Not Installed') {
        Return
    }
    If ($WPFUpdatesOSDSUSVersion.Text -eq $WPFUpdatesOSDSUSCurrentVerTextBox.Text) {
        Update-Log -Data 'OSDSUS is up to date' -class Information
        Return
    }
    #$WPFUpdatesOSDBOutOfDateTextBlock.Visibility = "Visible"
    $WPFUpdatesOSDListBox.items.add('A software update module is out of date. Please click the Install / Update button to update it.') | Out-Null
    Update-Log -Data 'OSDSUS appears to be out of date. Run the upgrade Function from within WIM Witch to resolve' -class Warning

    Return
}

#Function to check for superceded updates
Function Test-Superceded($action, $OS, $Build) {
    Update-Log -Data 'Checking WIM Witch Update store for superseded updates' -Class Information
    $path = $PSScriptRoot + '\updates\' + $OS + '\' + $Build + '\' #sets base path

    if ((Test-Path -Path $path) -eq $false) {
        Update-Log -Data 'No updates found, likely not yet downloaded. Skipping supersedense check...' -Class Warning
        return
    }

    $Children = Get-ChildItem -Path $path  #query sub directories

    foreach ($Children in $Children) {
        $path1 = $path + $Children
        $sprout = Get-ChildItem -Path $path1


        foreach ($sprout in $sprout) {
            $path3 = $path1 + '\' + $sprout
            $fileinfo = Get-ChildItem -Path $path3
            foreach ($file in $fileinfo) {
                $StillCurrent = Get-OSDUpdate | Where-Object { $_.FileName -eq $file }
                If ($null -eq $StillCurrent) {
                    Update-Log -data "$file no longer current" -Class Warning
                    if ($action -eq 'delete') {
                        Update-Log -data "Deleting $path3" -class Warning
                        Remove-Item -Path $path3 -Recurse -Force
                    }
                    if ($action -eq 'audit') {

                        # $WPFUpdatesOSDBSupercededExistTextBlock.Visibility = "Visible"
                        $WPFUpdatesOSDListBox.items.add('Superceded updates discovered. Please select the versions of Windows 10 you are supporting and click Update')

                        Return
                    }
                }
                else {
                    Update-Log -data "$file is still current" -Class Information
                }
            }
        }
    }
    Update-Log -data 'Supersedense check complete.' -Class Information
}

#Function to download new patches with OSDSUS
Function Get-WindowsPatches($build, $OS) {

    Write-Host $build
    Write-Host $OS

    Update-Log -Data "Downloading SSU updates for $OS $build" -Class Information
    try {
        Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'SSU' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\SSU
    }
    catch {
        Update-Log -data 'Failed to download SSU update' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

    Update-Log -Data "Downloading AdobeSU updates for $OS $build" -Class Information
    try {
        Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'AdobeSU' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\AdobeSU
    }
    catch {
        Update-Log -data 'Failed to download AdobeSU update' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

    Update-Log -Data "Downloading LCU updates for $OS $build" -Class Information
    try {
        Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'LCU' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\LCU
    }
    catch {
        Update-Log -data 'Failed to download LCU update' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }
    Update-Log -Data "Downloading .Net updates for $OS $build" -Class Information
    try {
        Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'DotNet' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\DotNet
    }
    catch {
        Update-Log -data 'Failed to download .Net update' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

    Update-Log -Data "Downloading .Net CU updates for $OS $build" -Class Information
    try {
        Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'DotNetCU' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\DotNetCU
    }
    catch {
        Update-Log -data 'Failed to download .Net CU update' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

    if ($WPFUpdatesCBEnableOptional.IsChecked -eq $True) {
        try {
            Update-Log -Data "Downloading optional updates for $OS $build" -Class Information
            Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'Optional' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\Optional
        }
        catch {
            Update-Log -data 'Failed to download optional update' -Class Error
            Update-Log -data $_.Exception.Message -class Error
        }
    }

    if ($WPFUpdatesCBEnableDynamic.IsChecked -eq $True) {
        try {
            Update-Log -Data "Downloading dynamic updates for $OS $build" -Class Information
            Get-OSDUpdate -ErrorAction Stop | Where-Object { $_.UpdateOS -eq $OS -and $_.UpdateArch -eq 'x64' -and $_.UpdateBuild -eq $build -and $_.UpdateGroup -eq 'SetupDU' } | Get-DownOSDUpdate -DownloadPath $PSScriptRoot\updates\$OS\$build\Dynamic
        }
        catch {
            Update-Log -data 'Failed to download dynamic update' -Class Error
            Update-Log -data $_.Exception.Message -class Error
        }
    }


    Update-Log -Data "Downloading completed for $OS $build" -Class Information


}

#Function to remove superceded updates and initate new patch download
Function Update-PatchSource {

    Update-Log -Data 'attempting to start download Function' -Class Information
    if ($WPFUSCBSelectCatalogSource.SelectedItem -eq 'OSDSUS') {
        if ($WPFUpdatesW10Main.IsChecked -eq $true) {
            if ($WPFUpdatesW10_22H2.IsChecked -eq $true) {
                Test-Superceded -action delete -build 22H2 -OS 'Windows 10'
                Get-WindowsPatches -build 22H2 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_21H2.IsChecked -eq $true) {
                Test-Superceded -action delete -build 21H2 -OS 'Windows 10'
                Get-WindowsPatches -build 21H2 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_21H1.IsChecked -eq $true) {
                Test-Superceded -action delete -build 21H1 -OS 'Windows 10'
                Get-WindowsPatches -build 21H1 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_20H2.IsChecked -eq $true) {
                Test-Superceded -action delete -build 20H2 -OS 'Windows 10'
                Get-WindowsPatches -build 20H2 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_2004.IsChecked -eq $true) {
                Test-Superceded -action delete -build 2004 -OS 'Windows 10'
                Get-WindowsPatches -build 2004 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_1909.IsChecked -eq $true) {
                Test-Superceded -action delete -build 1909 -OS 'Windows 10'
                Get-WindowsPatches -build 1909 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_1903.IsChecked -eq $true) {
                Test-Superceded -action delete -build 1903 -OS 'Windows 10'
                Get-WindowsPatches -build 1903 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_1809.IsChecked -eq $true) {
                Test-Superceded -action delete -build 1809 -OS 'Windows 10'
                Get-WindowsPatches -build 1809 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_1803.IsChecked -eq $true) {
                Test-Superceded -action delete -build 1803 -OS 'Windows 10'
                Get-WindowsPatches -build 1803 -OS 'Windows 10'
            }
            if ($WPFUpdatesW10_1709.IsChecked -eq $true) {
                Test-Superceded -action delete -build 1709 -OS 'Windows 10'
                Get-WindowsPatches -build 1709 -OS 'Windows 10'
            }
            #Get-OneDrive
        }
        if ($WPFUpdatesS2019.IsChecked -eq $true) {
            Test-Superceded -action delete -build 1809 -OS 'Windows Server'
            Get-WindowsPatches -build 1809 -OS 'Windows Server'
        }
        if ($WPFUpdatesS2016.IsChecked -eq $true) {
            Test-Superceded -action delete -build 1607 -OS 'Windows Server'
            Get-WindowsPatches -build 1607 -OS 'Windows Server'
        }
        if ($WPFUpdatesS2022.IsChecked -eq $true) {
            Test-Superceded -action delete -build 21H2 -OS 'Windows Server'
            Get-WindowsPatches -build 21H2 -OS 'Windows Server'
        }

        if ($WPFUpdatesW11Main.IsChecked -eq $true) {

            if ($WPFUpdatesW11_22H2.IsChecked -eq $true) {

                Test-Superceded -action delete -build 22H2 -OS 'Windows 11'
                Get-WindowsPatches -build 22H2 -OS 'Windows 11'
            }
            if ($WPFUpdatesW11_21h2.IsChecked -eq $true) {
                Write-Host '21H2'
                Test-Superceded -action delete -build 21H2 -OS 'Windows 11'
                Get-WindowsPatches -build 21H2 -OS 'Windows 11'

            }

        }
        Get-OneDrive
    }

    if ($WPFUSCBSelectCatalogSource.SelectedItem -eq 'ConfigMgr') {
        if ($WPFUpdatesW10Main.IsChecked -eq $true) {
            if ($WPFUpdatesW10_22H2.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '22H2'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '22H2'
            }
            if ($WPFUpdatesW10_21H2.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '21H2'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '21H2'
            }
            if ($WPFUpdatesW10_21H1.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '21H1'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '21H1'
            }
            if ($WPFUpdatesW10_20H2.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '20H2'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '20H2'
            }
            if ($WPFUpdatesW10_2004.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '2004'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '2004'
            }
            if ($WPFUpdatesW10_1909.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '1909'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '1909'
            }
            if ($WPFUpdatesW10_1903.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '1903'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '1903'
            }
            if ($WPFUpdatesW10_1809.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '1809'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '1809'
            }
            if ($WPFUpdatesW10_1803.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '1803'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '1803'
            }
            if ($WPFUpdatesW10_1709.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver '1709'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -ver '1709'
            }
            #Get-OneDrive
        }
        if ($WPFUpdatesS2019.IsChecked -eq $true) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver '1809'
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver '1809'
        }
        if ($WPFUpdatesS2016.IsChecked -eq $true) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver '1607'
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver '1607'
        }
        if ($WPFUpdatesS2022.IsChecked -eq $true) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver '21H2'
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver '21H2'
        }
        if ($WPFUpdatesW11Main.IsChecked -eq $true) {
            if ($WPFUpdatesW11_21H2.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 11' -Ver '21H2'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 11' -ver '21H2'
            }
            if ($WPFUpdatesW11_22H2.IsChecked -eq $true) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 11' -Ver '22H2'
                Invoke-MEMCMUpdatecatalog -prod 'Windows 11' -ver '22H2'
            }

            #Invoke-MEMCMUpdateSupersedence -prod "Windows 11" -Ver "21H2"
            #Invoke-MEMCMUpdatecatalog -prod "Windows 11" -Ver "21H2"
            #Get-OneDrive
        }
        Get-OneDrive
    }
    Update-Log -data 'All downloads complete' -class Information
}

Function Deploy-LCU($packagepath) {
    $osver = Get-WindowsType
    #write-host $osver

    if ($osver -eq 'Windows 10') {
        $executable = "$env:windir\system32\expand.exe"
        $filename = (Get-ChildItem $packagepath).name


        Update-Log -Data 'Extracting LCU Package content to staging folder...' -Class Information
        Start-Process $executable -args @("`"$packagepath\$filename`"", '/f:*.CAB', "`"$PSScriptRoot\staging`"") -Wait -ErrorAction Stop
        $cabs = (Get-Item $PSScriptRoot\staging\*.cab)

        #MMSMOA2022
        Update-Log -data 'Applying SSU...' -class information
        foreach ($cab in $cabs) {

            if ($cab -like '*SSU*') {
                Update-Log -data $cab -class Information

                if ($demomode -eq $false) { Add-WindowsPackage -Path $WPFMISMountTextBox.Text -PackagePath $cab -ErrorAction stop | Out-Null }
                else {
                    $string = 'Demo mode active - Not applying ' + $cab
                    Update-Log -data $string -Class Warning
                }
            }

        }



        Update-Log -data 'Applying LCU...' -class information
        foreach ($cab in $cabs) {
            if ($cab -notlike '*SSU*') {
                Update-Log -data $cab -class information
                if ($demomode -eq $false) { Add-WindowsPackage -Path $WPFMISMountTextBox.Text -PackagePath $cab -ErrorAction stop | Out-Null }
                else {
                    $string = 'Demo mode active - Not applying ' + $cab
                    Update-Log -data $string -Class Warning
                }
            }

            #Add-WindowsPackage -path $WPFMISMountTextBox.Text -PackagePath $cab -erroraction stop| Out-Null}}
        }


    }
    if ($osver -eq 'Windows 11') {
        #copy file to staging
        Update-Log -data 'Copying LCU file to staging folder...' -class information

        $filename = (Get-ChildItem -Path $packagepath -Name)
        Copy-Item -Path $packagepath\$filename -Destination $PSScriptRoot\staging -Force
        #rename file

        #  $filename = Split-Path -Path $packagepath -Leaf
        # write-host $filename
        Update-Log -data 'Changing file extension type from CAB to MSU...' -class information
        $basename = (Get-Item -Path $PSScriptRoot\staging\$filename).BaseName
        $newname = $basename + '.msu'
        Rename-Item -Path $PSScriptRoot\staging\$filename -NewName $newname

        Update-Log -data 'Applying LCU...' -class information
        Update-Log -data $PSScriptRoot\staging\$newname -class information
        $updatename = (Get-Item -Path $packagepath).name
        Update-Log -data $updatename -Class Information

        try {
            #    Add-WindowsPackage -path $WPFMISMountTextBox.Text -PackagePath $PSScriptRoot\staging\$newname -ErrorAction Stop
            if ($demomode -eq $false) { Add-WindowsPackage -Path $WPFMISMountTextBox.Text -PackagePath $PSScriptRoot\staging\$newname -ErrorAction Stop | Out-Null }
            else {
                $string = 'Demo mode active - Not applying ' + $updatename
                Update-Log -data $string -Class Warning
            }


        }

        catch {
            Update-Log -data 'Failed to apply update' -class Warning
            Update-Log -data $_.Exception.Message -class Warning
        }


    }

}

#Function to apply updates to mounted WIM
Function Deploy-Updates($class) {

    if (($class -eq 'AdobeSU') -and ($WPFSourceWIMImgDesTextBox.text -like 'Windows Server 20*') -and ($WPFSourceWIMImgDesTextBox.text -notlike '*(Desktop Experience)')) {
        Update-Log -Data 'Skipping Adobe updates for Server Core build' -Class Information
        return
    }

    $OS = Get-WindowsType
    $buildnum = Get-WinVersionNumber


    if ($buildnum -eq '2009') { $buildnum = '20H2' }


    If (($WPFSourceWimVerTextBox.text -like '10.0.18362.*') -and (($class -ne 'Dynamic') -and ($class -notlike 'PE*'))) {
        $mountdir = $WPFMISMountTextBox.Text
        reg LOAD HKLM\OFFLINE $mountdir\Windows\System32\Config\SOFTWARE | Out-Null
        $regvalues = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\OFFLINE\Microsoft\Windows NT\CurrentVersion\' )
        $buildnum = $regvalues.ReleaseId
        reg UNLOAD HKLM\OFFLINE | Out-Null
    }


    If (($WPFSourceWimVerTextBox.text -like '10.0.18362.*') -and (($class -eq 'Dynamic') -or ($class -like 'PE*'))) {
        $windowsver = Get-WindowsImage -ImagePath ($PSScriptRoot + '\staging\' + $WPFMISWimNameTextBox.text) -Index 1
        $Vardate = (Get-Date -Year 2019 -Month 10 -Day 01)
        if ($windowsver.CreatedTime -gt $vardate) { $buildnum = 1909 }
        else
        { $buildnum = 1903 }
    }

    if ($class -eq 'PESSU') {
        $IsPE = $true
        $class = 'SSU'
    }

    if ($class -eq 'PELCU') {
        $IsPE = $true
        $class = 'LCU'
    }

    $path = $PSScriptRoot + '\updates\' + $OS + '\' + $buildnum + '\' + $class + '\'

    if ((Test-Path $path) -eq $False) {
        Update-Log -data "$path does not exist. There are no updates of this class to apply" -class Warning
        return
    }

    $Children = Get-ChildItem -Path $path
    foreach ($Children in $Children) {
        $compound = $path + $Children
        Update-Log -Data "Applying $Children" -Class Information
        try {
            if ($class -eq 'Dynamic') {
                #Update-Log -data "Applying Dynamic to media" -Class Information
                $mediafolder = $PSScriptRoot + '\staging\media\sources'
                #write-host $compound
                #write-host $mediafolder
                $DynUpdates = (Get-ChildItem -Path $compound -Name)
                foreach ($DynUpdate in $DynUpdates) {

                    $text = $compound + '\' + $DynUpdate
                    #write-host $text
                    Start-Process -FilePath c:\windows\system32\expand.exe -args @("`"$text`"", '-F:*', "`"$mediafolder`"") -Wait
                }
            }
            elseif ($IsPE -eq $true) { Add-WindowsPackage -Path ($PSScriptRoot + '\staging\mount') -PackagePath $compound -ErrorAction stop | Out-Null }
            else {
                if ($class -eq 'LCU') {
                    if (($os -eq 'Windows 10') -and (($buildnum -eq '2004') -or ($buildnum -eq '2009') -or ($buildnum -eq '20H2') -or ($buildnum -eq '21H1') -or ($buildnum -eq '21H2') -or ($buildnum -eq '22H2'))) {
                        Update-Log -data 'Processing the LCU package to retrieve SSU...' -class information
                        Deploy-LCU -packagepath $compound
                    }
                    elseif ($os -eq 'Windows 11') {
                        Update-Log -data 'Windows 11 required LCU modification started...' -Class Information
                        Deploy-LCU -packagepath $compound
                    }

                    else {

                        Add-WindowsPackage -Path $WPFMISMountTextBox.Text -PackagePath $compound -ErrorAction stop | Out-Null
                    }
                }

                else { Add-WindowsPackage -Path $WPFMISMountTextBox.Text -PackagePath $compound -ErrorAction stop | Out-Null }

            }
        }
        catch {
            Update-Log -data 'Failed to apply update' -class Warning
            Update-Log -data $_.Exception.Message -class Warning
        }
    }
}

#Function to select AppX packages to yank
Function Select-Appx {
    $appx1903 = @('Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Getstarted_7.3.20251.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.HEIFImageExtension_1.0.13472.0_x64__8wekyb3d8bbwe'
        'Microsoft.Messaging_2019.125.32.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Microsoft3DViewer_5.1902.20012.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftOfficeHub_18.1901.1141.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftSolitaireCollection_4.2.11280.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftStickyNotes_3.1.53.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MixedReality.Portal_2000.19010.1151.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MSPaint_2019.213.1858.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Office.OneNote_16001.11126.20076.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.OneConnect_5.1902.361.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.People_2019.123.2346.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Print3D_3.3.311.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ScreenSketch_2018.1214.231.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.SkypeApp_14.35.152.0_neutral_~_kzf8qxf38zg5c'
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.VP9VideoExtensions_1.0.13333.0_x64__8wekyb3d8bbwe'
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WebMediaExtensions_1.0.13321.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WebpImageExtension_1.0.12821.0_x64__8wekyb3d8bbwe'
        'Microsoft.Windows.Photos_2019.18114.19418.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsAlarms_2019.105.629.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCalculator_2019.105.612.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCamera_2018.826.78.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.windowscommunicationsapps_16005.11029.20108.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsFeedbackHub_2019.226.2324.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsMaps_2019.108.627.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsSoundRecorder_2019.105.618.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsStore_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxApp_48.48.7001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGameOverlay_1.32.17005.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGamingOverlay_2.26.14003.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.YourPhone_2018.1128.231.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneMusic_2019.18111.17311.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneVideo_2019.18111.17311.0_neutral_~_8wekyb3d8bbwe')
    $appx1809 = @(
        'Microsoft.BingWeather_4.25.12127.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.DesktopAppInstaller_2018.720.2137.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.GetHelp_10.1706.10441.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Getstarted_6.13.11581.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.HEIFImageExtension_1.0.11792.0_x64__8wekyb3d8bbwe'
        'Microsoft.Messaging_2018.727.1430.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Microsoft3DViewer_4.1808.15012.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftOfficeHub_2017.1219.520.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftSolitaireCollection_4.1.5252.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftStickyNotes_2.0.13.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MixedReality.Portal_2000.18081.1242.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MSPaint_4.1807.12027.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Office.OneNote_16001.10228.20003.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.OneConnect_5.1807.1991.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.People_2018.516.2011.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Print3D_3.0.1521.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ScreenSketch_2018.731.48.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.SkypeApp_14.26.95.0_neutral_~_kzf8qxf38zg5c'
        'Microsoft.StorePurchaseApp_11805.1001.813.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.VP9VideoExtensions_1.0.12342.0_x64__8wekyb3d8bbwe'
        'Microsoft.Wallet_2.2.18179.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WebMediaExtensions_1.0.12341.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WebpImageExtension_1.0.11551.0_x64__8wekyb3d8bbwe'
        'Microsoft.Windows.Photos_2018.18051.21218.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsAlarms_2018.516.2059.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCalculator_2018.501.612.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCamera_2018.425.120.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.windowscommunicationsapps_2015.9330.21365.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsFeedbackHub_2018.822.2.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsMaps_2018.523.2143.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsSoundRecorder_2018.713.2154.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsStore_11805.1001.4913.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Xbox.TCUI_1.11.28003.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxApp_41.41.18001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGameOverlay_1.32.17005.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGamingOverlay_2.20.22001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxIdentityProvider_12.44.20001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.YourPhone_2018.727.2137.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneMusic_2019.18052.20211.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneVideo_2019.18052.20211.0_neutral_~_8wekyb3d8bbwe'
    )
    $appx1803 = @(
        'Microsoft.BingWeather_4.22.3254.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.DesktopAppInstaller_1.8.15011.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.GetHelp_10.1706.10441.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Getstarted_6.9.10602.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Messaging_2018.222.2231.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Microsoft3DViewer_2.1803.8022.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftOfficeHub_2017.1219.520.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftSolitaireCollection_4.0.1301.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MicrosoftStickyNotes_2.0.13.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.MSPaint_3.1803.5027.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Office.OneNote_2015.8827.20991.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.OneConnect_4.1801.521.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.People_2018.215.110.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Print3D_2.0.3621.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.SkypeApp_12.13.274.0_neutral_~_kzf8qxf38zg5c'
        'Microsoft.StorePurchaseApp_11712.1801.10024.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Wallet_2.1.18009.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WebMediaExtensions_1.0.3102.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Windows.Photos_2018.18011.15918.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsAlarms_2018.302.1846.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCalculator_2018.302.144.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsCamera_2017.1117.80.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.windowscommunicationsapps_2015.8827.22055.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsFeedbackHub_2018.302.2011.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsMaps_2018.209.2206.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsSoundRecorder_2018.302.1842.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.WindowsStore_11712.1001.2313.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.Xbox.TCUI_1.11.28003.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxApp_38.38.14002.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGameOverlay_1.26.6001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxGamingOverlay_1.15.1001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxIdentityProvider_12.36.15002.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneMusic_2019.17112.19011.0_neutral_~_8wekyb3d8bbwe'
        'Microsoft.ZuneVideo_2019.17112.19011.0_neutral_~_8wekyb3d8bbwe' )
    $appx1709 = @(
        'Microsoft.BingWeather_4.21.2492.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_1.8.4001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.1811.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_5.11.1641.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Messaging_2017.815.2052.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_1.1707.26019.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_2017.715.118.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_3.17.8162.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_1.8.2.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2.1709.4027.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_2015.8366.57611.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.OneConnect_3.1708.2224.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2017.823.2207.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Print3D_1.0.2422.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_11.18.596.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11706.1707.7104.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Wallet_1.0.16328.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2017.37071.16410.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2017.828.2050.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2017.828.2012.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2017.727.20.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.windowscommunicationsapps_2015.8241.41275.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_1.1705.2121.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2017.814.2249.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2017.605.2103.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11706.1002.94.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.8.24001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_31.32.16002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.20.25002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_2017.605.1240.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.17063.24021.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.17063.24021.0_neutral_~_8wekyb3d8bbwe' )
    $appx2004 = @(
        'Microsoft.549981C3F5F10_1.1911.21713.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_8.2.22942.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.22742.0_x64__8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_6.1908.2042.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.1903.1152.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.4.8204.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_3.6.73.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MixedReality.Portal_2000.19081.1301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2019.729.2301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_16001.12026.20112.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2019.305.632.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2019.904.1644.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_14.53.77.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.27323.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.22681.0_x64__8wekyb3d8bbwe',
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.20875.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.22753.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2019.19071.12548.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2019.807.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.1906.55.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2018.826.98.0_neutral_~_8wekyb3d8bbwe',
        'microsoft.windowscommunicationsapps_16005.11629.20316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2019.1111.2029.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2019.716.2316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2019.716.2313.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11910.1002.513.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe' )
    $appx2009 = @(
        'Microsoft.549981C3F5F10_1.1911.21713.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_8.2.22942.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.22742.0_x64__8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_6.1908.2042.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftEdge.Stable_84.0.522.52_neutral__8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.1903.1152.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.4.8204.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_3.6.73.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MixedReality.Portal_2000.19081.1301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2019.729.2301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_16001.12026.20112.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2019.305.632.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2019.904.1644.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_14.53.77.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.27323.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.22681.0_x64__8wekyb3d8bbwe',
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.20875.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.22753.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2019.19071.12548.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2019.807.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.1906.55.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2018.826.98.0_neutral_~_8wekyb3d8bbwe',
        'microsoft.windowscommunicationsapps_16005.11629.20316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2019.1111.2029.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2019.716.2316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2019.716.2313.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11910.1002.513.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe')
    $appx21H1 = @(
        'Microsoft.549981C3F5F10_1.1911.21713.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_8.2.22942.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.22742.0_x64__8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_6.1908.2042.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.1903.1152.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.4.8204.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_3.6.73.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MixedReality.Portal_2000.19081.1301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2019.729.2301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_16001.12026.20112.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2019.305.632.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2019.904.1644.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_14.53.77.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.27323.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.22681.0_x64__8wekyb3d8bbwe',
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.20875.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.22753.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2019.19071.12548.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2019.807.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.1906.55.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2018.826.98.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.windowscommunicationsapps_16005.11629.20316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2019.1111.2029.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2019.716.2316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2019.716.2313.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11910.1002.513.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe'
    )
    $appxWin11_21H2 = @(
        'Microsoft.549981C3F5F10_2.2106.2807.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingNews_4.7.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.9.2002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2020.812.2125.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GamingApp_2021.427.138.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.2008.32311.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_10.2.41172.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.40978.0_x64__8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.2104.12721.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.6.3102.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_4.1.2.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Paint_10.2104.17.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2020.901.1724.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.PowerAutomateDesktop_10.0.561.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2021.2104.2.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SecHealthUI_1000.22000.1.0_neutral__8wekyb3d8bbwe',
        'Microsoft.StorePurchaseApp_12008.1001.113.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Todos_2.33.33351.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.UI.Xaml.2.4_2.42007.9001.0_x64__8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.29231.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.41182.0_x64__8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.40831.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.32731.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_21.21030.25003.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2021.2101.27.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.2012.21.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2020.503.58.0_neutral_~_8wekyb3d8bbwe',
        'microsoft.windowscommunicationsapps_16005.12827.20400.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2021.427.1821.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2021.2012.10.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsNotepad_10.2102.13.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2021.2012.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_12104.1001.113.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsTerminal_2021.226.1915.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.50.24002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.21012.10511.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.21012.10511.0_neutral_~_8wekyb3d8bbwe',
        'MicrosoftWindows.Client.WebExperience_321.14700.0.9_neutral_~_cw5n1h2txyewy')
    $appxWin10_21H2 = @(
        'Microsoft.549981C3F5F10_1.1911.21713.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_8.2.22942.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.22742.0_x64__8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_6.1908.2042.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.1903.1152.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.4.8204.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_3.6.73.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MixedReality.Portal_2000.19081.1301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2019.729.2301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_16001.12026.20112.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2019.305.632.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2019.904.1644.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_14.53.77.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.27323.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.22681.0_x64__8wekyb3d8bbwe',
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.20875.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.22753.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2019.19071.12548.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2019.807.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.1906.55.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2018.826.98.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.windowscommunicationsapps_16005.11629.20316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2019.1111.2029.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2019.716.2316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2019.716.2313.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11910.1002.513.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe'
    )
    $appxWin11_22H2 = @('Clipchamp.Clipchamp_2.2.8.0_neutral_~_yxz26nhyzhsrt',
        'Microsoft.549981C3F5F10_3.2204.14815.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingNews_4.2.27001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.53.33420.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2022.310.2333.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GamingApp_2021.427.138.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.2201.421.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_2021.2204.1.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.43012.0_x64__8wekyb3d8bbwe',
        'Microsoft.HEVCVideoExtension_1.0.50361.0_x64__8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.2204.1141.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.12.3171.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_4.2.2.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Paint_11.2201.22.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2020.901.1724.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.PowerAutomateDesktop_10.0.3735.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.RawImageExtension_2.1.30391.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2022.2201.12.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SecHealthUI_1000.22621.1.0_x64__8wekyb3d8bbwe',
        'Microsoft.StorePurchaseApp_12008.1001.113.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Todos_2.54.42772.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.50901.0_x64__8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.42192.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.42351.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_21.21030.25003.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2022.2202.24.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.2103.8.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2022.2201.4.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.windowscommunicationsapps_16005.14326.20544.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2022.106.2230.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2022.2202.6.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsNotepad_11.2112.32.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2021.2103.28.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_22204.1400.4.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsTerminal_3001.12.10983.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28004.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.47.2385.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.622.3232.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_1.22022.147.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_11.2202.46.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.22020.10021.0_neutral_~_8wekyb3d8bbwe',
        'MicrosoftCorporationII.QuickAssist_2022.414.1758.0_neutral_~_8wekyb3d8bbwe',
        'MicrosoftWindows.Client.WebExperience_421.20070.195.0_neutral_~_cw5n1h2txyewy'
    )
    $appxWin10_22H2 = @(
        'Microsoft.549981C3F5F10_1.1911.21713.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.BingWeather_4.25.20211.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.DesktopAppInstaller_2019.125.2243.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.GetHelp_10.1706.13331.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Getstarted_8.2.22942.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.HEIFImageExtension_1.0.22742.0_x64__8wekyb3d8bbwe',
        'Microsoft.Microsoft3DViewer_6.1908.2042.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftOfficeHub_18.1903.1152.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftSolitaireCollection_4.4.8204.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MicrosoftStickyNotes_3.6.73.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MixedReality.Portal_2000.19081.1301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.MSPaint_2019.729.2301.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Office.OneNote_16001.12026.20112.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.People_2019.305.632.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ScreenSketch_2019.904.1644.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.SkypeApp_14.53.77.0_neutral_~_kzf8qxf38zg5c',
        'Microsoft.StorePurchaseApp_11811.1001.1813.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.VCLibs.140.00_14.0.27323.0_x64__8wekyb3d8bbwe',
        'Microsoft.VP9VideoExtensions_1.0.22681.0_x64__8wekyb3d8bbwe',
        'Microsoft.Wallet_2.4.18324.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebMediaExtensions_1.0.20875.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WebpImageExtension_1.0.22753.0_x64__8wekyb3d8bbwe',
        'Microsoft.Windows.Photos_2019.19071.12548.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsAlarms_2019.807.41.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCalculator_2020.1906.55.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsCamera_2018.826.98.0_neutral_~_8wekyb3d8bbwe',
        'microsoft.windowscommunicationsapps_16005.11629.20316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsFeedbackHub_2019.1111.2029.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsMaps_2019.716.2316.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsSoundRecorder_2019.716.2313.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.WindowsStore_11910.1002.513.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.Xbox.TCUI_1.23.28002.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxApp_48.49.31001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGameOverlay_1.46.11001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxGamingOverlay_2.34.28001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxIdentityProvider_12.50.6001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.XboxSpeechToTextOverlay_1.17.29001.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.YourPhone_2019.430.2026.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneMusic_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe',
        'Microsoft.ZuneVideo_2019.19071.19011.0_neutral_~_8wekyb3d8bbwe'
    )

    $OS = Get-WindowsType
    #$buildnum = Get-WinVersionNumber
    $buildnum = $WPFSourceWimTBVersionNum.text

    if ($OS -eq 'Windows 10') {
        if ($buildnum -eq '1909') { $exappxs = Write-Output $appx1903 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if ($buildnum -eq '1809') { $exappxs = Write-Output $appx1809 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if (($buildnum -eq '2009') -or ($buildnum -eq '20H2')) { $exappxs = Write-Output $appx2009 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if ($buildnum -eq '21H1') { $exappxs = Write-Output $appx21H1 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if ($buildnum -eq '21H2') { $exappxs = Write-Output $appxWin10_21H2 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if ($buildnum -eq '22H2') { $exappxs = Write-Output $appxWin10_22H2 | Out-GridView -Title 'Select apps to remove' -PassThru }

    }
    if ($OS -eq 'Windows 11') {
        if ($buildnum -eq '21H2') { $exappxs = Write-Output $appxWin11_21H2 | Out-GridView -Title 'Select apps to remove' -PassThru }
        if ($buildnum -eq '22H2') { $exappxs = Write-Output $appxWin11_22H2 | Out-GridView -Title 'Select apps to remove' -PassThru }
    }

    if ($null -eq $exappxs) {
        Update-Log -Data 'No apps were selected' -Class Warning
    }
    if ($null -ne $exappxs) {
        Update-Log -data 'The following apps were selected for removal:' -Class Information
        Foreach ($exappx in $exappxs) {
            Update-Log -Data $exappx -Class Information
        }

        $WPFAppxTextBox.Text = $exappxs
        return $exappxs
    }
}

#Function to remove appx packages
Function Remove-Appx($array) {
    $exappxs = $array
    Update-Log -data 'Starting AppX removal' -class Information
    foreach ($exappx in $exappxs) {
        try {
            Remove-AppxProvisionedPackage -Path $WPFMISMountTextBox.Text -PackageName $exappx -ErrorAction Stop | Out-Null
            Update-Log -data "Removing $exappx" -Class Information
        }
        catch {
            Update-Log -Data "Failed to remove $exappx" -Class Error
            Update-Log -Data $_.Exception.Message -Class Error
        }
    }
    return
}

#Function to remove unwanted image indexes
Function Remove-OSIndex {
    Update-Log -Data 'Attempting to remove unwanted image indexes' -Class Information
    $wimname = Get-Item -Path $PSScriptRoot\Staging\*.wim

    Update-Log -Data "Found Image $wimname" -Class Information
    $IndexesAll = Get-WindowsImage -ImagePath $wimname | ForEach-Object { $_.ImageName }
    $IndexSelected = $WPFSourceWIMImgDesTextBox.Text
    foreach ($Index in $IndexesAll) {
        Update-Log -data "$Index is being evaluated"
        If ($Index -eq $IndexSelected) {
            Update-Log -Data "$Index is the index we want to keep. Skipping." -Class Information | Out-Null
        }
        else {
            Update-Log -data "Deleting $Index from WIM" -Class Information
            Remove-WindowsImage -ImagePath $wimname -Name $Index -InformationAction SilentlyContinue | Out-Null

        }
    }
}

#Function to select which folder to save Autopilot JSON file to
Function Select-NewJSONDir {

    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Select the folder to save JSON'
    $null = $browser.ShowDialog()
    $SaveDir = $browser.SelectedPath
    $WPFJSONTextBoxSavePath.text = $SaveDir
    $text = "Autopilot profile save path selected: $SaveDir"
    Update-Log -Data $text -Class Information
}

Function Update-Autopilot {
    Update-Log -Data 'Uninstalling old WindowsAutopilotIntune module...' -Class Warning
    Uninstall-Module -Name WindowsAutopilotIntune -AllVersions
    Update-Log -Data 'Installing new WindowsAutopilotIntune module...' -Class Warning
    Install-Module -Name WindowsAutopilotIntune -Force
    $AutopilotUpdate = ([System.Windows.MessageBox]::Show('WIM Witch needs to close and PowerShell needs to be restarted. Click OK to close WIM Witch.', 'Updating complete.', 'OK', 'warning'))
    if ($AutopilotUpdate -eq 'OK') {
        $form.Close()
        exit
    }
}

#Function to retrieve autopilot profile from intune
Function Get-WWAutopilotProfile($login, $path) {
    Update-Log -data 'Checking dependencies for Autopilot profile retrieval...' -Class Information

    try {
        Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -ErrorAction Stop
        Update-Log -Data 'NuGet is installed' -Class Information
    }
    catch {
        Update-Log -data 'NuGet is not installed. Installing now...' -Class Warning
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Update-Log -data 'NuGet is now installed' -Class Information
    }

    try {

        Import-Module -Name AzureAD -ErrorAction Stop | Out-Null
        Update-Log -data 'AzureAD Module is installed' -Class Information
    }
    catch {
        Update-Log -data 'AzureAD Module is not installed. Installing now...' -Class Warning
        Install-Module AzureAD -Force
        Update-Log -data 'AzureAD is now installed' -class Information
    }

    try {

        Import-Module -Name WindowsAutopilotIntune -ErrorAction Stop
        Update-Log -data 'WindowsAutopilotIntune module is installed' -Class Information
    }
    catch {

        Update-Log -data 'WindowsAutopilotIntune module is not installed. Installing now...' -Class Warning
        Install-Module WindowsAutopilotIntune -Force
        Update-Log -data 'WindowsAutopilotIntune module is now installed.' -class Information
    }

    $AutopilotInstalledVer = (Get-Module -Name windowsautopilotintune).Version
    Update-Log -Data "The currently installed version of the WindowsAutopilotIntune module is $AutopilotInstalledVer" -Class Information
    $AutopilotLatestVersion = (Find-Module -Name windowsautopilotintune).version
    Update-Log -data "The latest available version of the WindowsAutopilotIntune module is $AutopilotLatestVersion" -Class Information

    if ($AutopilotInstalledVer -eq $AutopilotLatestVersion) {
        Update-Log -data 'WindowsAutopilotIntune module is current. Continuing...' -Class Information
    }
    else {
        Update-Log -data 'WindowsAutopilotIntune module is out of date. Prompting the user to upgrade...'
        $UpgradeAutopilot = ([System.Windows.MessageBox]::Show("Would you like to update the WindowsAutopilotIntune module to version $AutopilotLatestVersion now?", 'Update Autopilot Module?', 'YesNo', 'warning'))
    }

    if ($UpgradeAutopilot -eq 'Yes') {
        Update-Log -Data 'User has chosen to update WindowsAutopilotIntune module' -Class Warning
        Update-Autopilot
    }
    elseif ($AutopilotInstalledVer -ne $AutopilotLatestVersion) {
        Update-Log -data 'User declined to update WindowsAutopilotIntune module. Continuing...' -Class Warning
    }


    Update-Log -data 'Connecting to Intune...' -Class Information
    if ($AutopilotInstalledVer -lt 3.9) { Connect-AutopilotIntune | Out-Null }
    else {
        Connect-MSGraph | Out-Null
    }

    Update-Log -data 'Connected to Intune' -Class Information

    Update-Log -data 'Retrieving profile...' -Class Information
    Get-AutoPilotProfile | Out-GridView -Title 'Select Autopilot profile' -PassThru | ConvertTo-AutoPilotConfigurationJSON | Out-File $path\AutopilotConfigurationFile.json -Encoding ASCII
    $text = $path + '\AutopilotConfigurationFile.json'
    Update-Log -data "Profile successfully created at $text" -Class Information
}

#Function to save current configuration
Function Save-Configuration {
    Param(
        [parameter(mandatory = $false, HelpMessage = 'config file')]
        [string]$filename,

        [parameter(mandatory = $false, HelpMessage = 'enable CM files')]
        [switch]$CM
    )

    $CurrentConfig = @{
        SourcePath       = $WPFSourceWIMSelectWIMTextBox.text
        SourceIndex      = $WPFSourceWimIndexTextBox.text
        SourceEdition    = $WPFSourceWIMImgDesTextBox.text
        UpdatesEnabled   = $WPFUpdatesEnableCheckBox.IsChecked
        AutopilotEnabled = $WPFJSONEnableCheckBox.IsChecked
        AutopilotPath    = $WPFJSONTextBox.text
        DriversEnabled   = $WPFDriverCheckBox.IsChecked
        DriverPath1      = $WPFDriverDir1TextBox.text
        DriverPath2      = $WPFDriverDir2TextBox.text
        DriverPath3      = $WPFDriverDir3TextBox.text
        DriverPath4      = $WPFDriverDir4TextBox.text
        DriverPath5      = $WPFDriverDir5TextBox.text
        AppxIsEnabled    = $WPFAppxCheckBox.IsChecked
        AppxSelected     = $WPFAppxTextBox.Text
        WIMName          = $WPFMISWimNameTextBox.text
        WIMPath          = $WPFMISWimFolderTextBox.text
        MountPath        = $WPFMISMountTextBox.text
        DotNetEnabled    = $WPFMISDotNetCheckBox.IsChecked
        OneDriveEnabled  = $WPFMISOneDriveCheckBox.IsChecked
        LPsEnabled       = $WPFCustomCBLangPacks.IsChecked
        LXPsEnabled      = $WPFCustomCBLEP.IsChecked
        FODsEnabled      = $WPFCustomCBFOD.IsChecked
        LPListBox        = $WPFCustomLBLangPacks.items
        LXPListBox       = $WPFCustomLBLEP.Items
        FODListBox       = $WPFCustomLBFOD.Items
        PauseAfterMount  = $WPFMISCBPauseMount.IsChecked
        PauseBeforeDM    = $WPFMISCBPauseDismount.IsChecked
        RunScript        = $WPFCustomCBRunScript.IsChecked
        ScriptTiming     = $WPFCustomCBScriptTiming.SelectedItem
        ScriptFile       = $WPFCustomTBFile.Text
        ScriptParams     = $WPFCustomTBParameters.Text
        CMImageType      = $WPFCMCBImageType.SelectedItem
        CMPackageID      = $WPFCMTBPackageID.Text
        CMImageName      = $WPFCMTBImageName.Text
        CMVersion        = $WPFCMTBImageVer.Text
        CMDescription    = $WPFCMTBDescription.Text
        CMBinDifRep      = $WPFCMCBBinDirRep.IsChecked
        CMSiteCode       = $WPFCMTBSitecode.Text
        CMSiteServer     = $WPFCMTBSiteServer.Text
        CMDPGroup        = $WPFCMCBDPDPG.SelectedItem
        CMDPList         = $WPFCMLBDPs.Items
        UpdateSource     = $WPFUSCBSelectCatalogSource.SelectedItem
        UpdateMIS        = $WPFMISCBCheckForUpdates.IsChecked
        AutoFillVersion  = $WPFCMCBImageVerAuto.IsChecked
        AutoFillDesc     = $WPFCMCBDescriptionAuto.IsChecked
        DefaultAppCB     = $WPFCustomCBEnableApp.IsChecked
        DefaultAppPath   = $WPFCustomTBDefaultApp.Text
        StartMenuCB      = $WPFCustomCBEnableStart.IsChecked
        StartMenuPath    = $WPFCustomTBStartMenu.Text
        RegFilesCB       = $WPFCustomCBEnableRegistry.IsChecked
        RegFilesLB       = $WPFCustomLBRegistry.Items
        SUOptional       = $WPFUpdatesCBEnableOptional.IsChecked
        SUDynamic        = $WPFUpdatesCBEnableDynamic.IsChecked

        ApplyDynamicCB   = $WPFMISCBDynamicUpdates.IsChecked
        UpdateBootCB     = $WPFMISCBBootWIM.IsChecked
        DoNotCreateWIMCB = $WPFMISCBNoWIM.IsChecked
        CreateISO        = $WPFMISCBISO.IsChecked
        ISOFileName      = $WPFMISTBISOFileName.Text
        ISOFilePath      = $WPFMISTBFilePath.Text
        UpgradePackageCB = $WPFMISCBUpgradePackage.IsChecked
        UpgradePackPath  = $WPFMISTBUpgradePackage.Text
        IncludeOptionCB  = $WPFUpdatesOptionalEnableCheckBox.IsChecked

        SourceVersion    = $WPFSourceWimTBVersionNum.text
    }

    if ($CM -eq $False) {

        Update-Log -data "Saving configuration file $filename" -Class Information

        try {
            $CurrentConfig | Export-Clixml -Path $PSScriptRoot\Configs\$filename -ErrorAction Stop
            Update-Log -data 'file saved' -Class Information
        }
        catch {
            Update-Log -data "Couldn't save file" -Class Error
        }
    }
    else {
        Update-Log -data "Saving ConfigMgr Image info for Package $filename" -Class Information

        $CurrentConfig.CMPackageID = $filename
        $CurrentConfig.CMImageType = 'Update Existing Image'

        $CurrentConfig.CMImageType

        if ((Test-Path -Path $PSScriptRoot\ConfigMgr\PackageInfo) -eq $False) {
            Update-Log -Data 'Creating ConfigMgr Package Info folder...' -Class Information

            try {
                New-Item -ItemType Directory -Path $PSScriptRoot\ConfigMgr\PackageInfo -ErrorAction Stop
            }
            catch {
                Update-Log -Data "Couldn't create the folder. Likely a permission issue" -Class Error
            }
        }
        try {
            $CurrentConfig | Export-Clixml -Path $PSScriptRoot\ConfigMgr\PackageInfo\$filename -Force -ErrorAction Stop
            Update-Log -data 'file saved' -Class Information
        }
        catch {
            Update-Log -data "Couldn't save file" -Class Error
        }
    }
}

#Function to import configurations from file
Function Get-Configuration($filename) {
    Update-Log -data "Importing config from $filename" -Class Information
    try {
        $settings = Import-Clixml -Path $filename -ErrorAction Stop
        Update-Log -data 'Config file read...' -Class Information
        $WPFSourceWIMSelectWIMTextBox.text = $settings.SourcePath
        $WPFSourceWimIndexTextBox.text = $settings.SourceIndex
        $WPFSourceWIMImgDesTextBox.text = $settings.SourceEdition
        $WPFUpdatesEnableCheckBox.IsChecked = $settings.UpdatesEnabled
        $WPFJSONEnableCheckBox.IsChecked = $settings.AutopilotEnabled
        $WPFJSONTextBox.text = $settings.AutopilotPath
        $WPFDriverCheckBox.IsChecked = $settings.DriversEnabled
        $WPFDriverDir1TextBox.text = $settings.DriverPath1
        $WPFDriverDir2TextBox.text = $settings.DriverPath2
        $WPFDriverDir3TextBox.text = $settings.DriverPath3
        $WPFDriverDir4TextBox.text = $settings.DriverPath4
        $WPFDriverDir5TextBox.text = $settings.DriverPath5
        $WPFAppxCheckBox.IsChecked = $settings.AppxIsEnabled
        $WPFAppxTextBox.text = $settings.AppxSelected -split ' '
        $WPFMISWimNameTextBox.text = $settings.WIMName
        $WPFMISWimFolderTextBox.text = $settings.WIMPath
        $WPFMISMountTextBox.text = $settings.MountPath
        $global:SelectedAppx = $settings.AppxSelected -split ' '
        $WPFMISDotNetCheckBox.IsChecked = $settings.DotNetEnabled
        $WPFMISOneDriveCheckBox.IsChecked = $settings.OneDriveEnabled
        $WPFCustomCBLangPacks.IsChecked = $settings.LPsEnabled
        $WPFCustomCBLEP.IsChecked = $settings.LXPsEnabled
        $WPFCustomCBFOD.IsChecked = $settings.FODsEnabled

        $WPFMISCBPauseMount.IsChecked = $settings.PauseAfterMount
        $WPFMISCBPauseDismount.IsChecked = $settings.PauseBeforeDM
        $WPFCustomCBRunScript.IsChecked = $settings.RunScript
        $WPFCustomCBScriptTiming.SelectedItem = $settings.ScriptTiming
        $WPFCustomTBFile.Text = $settings.ScriptFile
        $WPFCustomTBParameters.Text = $settings.ScriptParams
        $WPFCMCBImageType.SelectedItem = $settings.CMImageType
        $WPFCMTBPackageID.Text = $settings.CMPackageID
        $WPFCMTBImageName.Text = $settings.CMImageName
        $WPFCMTBImageVer.Text = $settings.CMVersion
        $WPFCMTBDescription.Text = $settings.CMDescription
        $WPFCMCBBinDirRep.IsChecked = $settings.CMBinDifRep
        $WPFCMTBSitecode.Text = $settings.CMSiteCode
        $WPFCMTBSiteServer.Text = $settings.CMSiteServer
        $WPFCMCBDPDPG.SelectedItem = $settings.CMDPGroup
        $WPFUSCBSelectCatalogSource.SelectedItem = $settings.UpdateSource
        $WPFMISCBCheckForUpdates.IsChecked = $settings.UpdateMIS

        $WPFCMCBImageVerAuto.IsChecked = $settings.AutoFillVersion
        $WPFCMCBDescriptionAuto.IsChecked = $settings.AutoFillDesc

        $WPFCustomCBEnableApp.IsChecked = $settings.DefaultAppCB
        $WPFCustomTBDefaultApp.Text = $settings.DefaultAppPath
        $WPFCustomCBEnableStart.IsChecked = $settings.StartMenuCB
        $WPFCustomTBStartMenu.Text = $settings.StartMenuPath
        $WPFCustomCBEnableRegistry.IsChecked = $settings.RegFilesCB
        $WPFUpdatesCBEnableOptional.IsChecked = $settings.SUOptional
        $WPFUpdatesCBEnableDynamic.IsChecked = $settings.SUDynamic

        $WPFMISCBDynamicUpdates.IsChecked = $settings.ApplyDynamicCB
        $WPFMISCBBootWIM.IsChecked = $settings.UpdateBootCB
        $WPFMISCBNoWIM.IsChecked = $settings.DoNotCreateWIMCB
        $WPFMISCBISO.IsChecked = $settings.CreateISO
        $WPFMISTBISOFileName.Text = $settings.ISOFileName
        $WPFMISTBFilePath.Text = $settings.ISOFilePath
        $WPFMISCBUpgradePackage.IsChecked = $settings.UpgradePackageCB
        $WPFMISTBUpgradePackage.Text = $settings.UpgradePackPath
        $WPFUpdatesOptionalEnableCheckBox.IsChecked = $settings.IncludeOptionCB

        $WPFSourceWimTBVersionNum.text = $settings.SourceVersion

        $LEPs = $settings.LPListBox
        $LXPs = $settings.LXPListBox
        $FODs = $settings.FODListBox
        $DPs = $settings.CMDPList
        $REGs = $settings.RegFilesLB



        Update-Log -data 'Configration set' -class Information

        Update-Log -data 'Clearing list boxes...' -Class Information
        $WPFCustomLBLangPacks.Items.Clear()
        $WPFCustomLBLEP.Items.Clear()
        $WPFCustomLBFOD.Items.Clear()
        $WPFCMLBDPs.Items.Clear()
        $WPFCustomLBRegistry.Items.Clear()


        Update-Log -data 'Populating list boxes...' -class Information
        foreach ($LEP in $LEPs) { $WPFCustomLBLangPacks.Items.Add($LEP) | Out-Null }
        foreach ($LXP in $LXPs) { $WPFCustomLBLEP.Items.Add($LXP) | Out-Null }
        foreach ($FOD in $FODs) { $WPFCustomLBFOD.Items.Add($FOD) | Out-Null }
        foreach ($DP in $DPs) { $WPFCMLBDPs.Items.Add($DP) | Out-Null }
        foreach ($REG in $REGs) { $WPFCustomLBRegistry.Items.Add($REG) | Out-Null }


        Import-WimInfo -IndexNumber $WPFSourceWimIndexTextBox.text -SkipUserConfirmation

        if ($WPFJSONEnableCheckBox.IsChecked -eq $true) {

            Invoke-ParseJSON -file $WPFJSONTextBox.text
        }

        if ($WPFCMCBImageType.SelectedItem -eq 'Update Existing Image') { Get-ImageInfo -PackID $settings.CMPackageID }

        Reset-MISCheckBox

    }

    catch
    { Update-Log -data "Could not import from $filename" -Class Error }

    Invoke-CheckboxCleanup
    Update-Log -data 'Config file loaded successfully' -Class Information
}

#Function to select configuration file
Function Select-Config {
    $SourceXML = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = "$PSScriptRoot\Configs"
        Filter           = 'XML (*.XML)|'
    }
    $null = $SourceXML.ShowDialog()
    $WPFSLLoadTextBox.text = $SourceXML.FileName
    Get-Configuration -filename $WPFSLLoadTextBox.text
}

#Function to reset reminder values from check boxes on the MIS tab when loading a config
Function Reset-MISCheckBox {
    Update-Log -data 'Refreshing MIS Values...' -class Information

    If ($WPFJSONEnableCheckBox.IsChecked -eq $true) {
        $WPFJSONButton.IsEnabled = $True
        $WPFMISJSONTextBox.Text = 'True'
    }
    If ($WPFDriverCheckBox.IsChecked -eq $true) {
        $WPFDriverDir1Button.IsEnabled = $True
        $WPFDriverDir2Button.IsEnabled = $True
        $WPFDriverDir3Button.IsEnabled = $True
        $WPFDriverDir4Button.IsEnabled = $True
        $WPFDriverDir5Button.IsEnabled = $True
        $WPFMISDriverTextBox.Text = 'True'
    }
    If ($WPFUpdatesEnableCheckBox.IsChecked -eq $true) {
        $WPFMISUpdatesTextBox.Text = 'True'
    }
    If ($WPFAppxCheckBox.IsChecked -eq $true) {
        $WPFAppxButton.IsEnabled = $True
        $WPFMISAppxTextBox.Text = 'True'
    }
    If ($WPFCustomCBEnableApp.IsChecked -eq $true) { $WPFCustomBDefaultApp.IsEnabled = $True }
    If ($WPFCustomCBEnableStart.IsChecked -eq $true) { $WPFCustomBStartMenu.IsEnabled = $True }
    If ($WPFCustomCBEnableRegistry.IsChecked -eq $true) {
        $WPFCustomBRegistryAdd.IsEnabled = $True
        $WPFCustomBRegistryRemove.IsEnabled = $True
    }

}

#Function to run WIM Witch from a config file
Function Invoke-RunConfigFile($filename) {
    Update-Log -Data "Loading the config file: $filename" -Class Information
    Get-Configuration -filename $filename
    Update-Log -Datversion $WWScriptVer
    Write-Output ' '
    Write-Output '##########################################################'
    Write-Output ' '
}

function Show-ClosingText {
    #Before you start bitching about write-host, write-output doesn't work with the exiting function. Suggestions are welcome.
    Write-Host ' '
    Write-Host '##########################################################'
    Write-Host ' '
    Write-Host 'Thank you for using WIM Witch. If you have any questions,'
    Write-Host 'comments, or suggestions, please reach out to me!'
    Write-Host ' '
    Write-Host '-Donna Ryan'
    Write-Host ' '
    Write-Host 'twitter: @TheNotoriousDRR'
    Write-Host 'www.MSEndpointmgr.com'
    Write-Host 'www.TheNotoriousDRR.com'
    Write-Host ' '
    Write-Host '##########################################################'
    if ($HiHungryImDad -eq $true) {
        Write-Host ' '
        Write-Host (invoke-dadjoke)
        Write-Host ' '
        Write-Host '##########################################################'
    }
}

function Show-OpeningText {
    Clear-Host
    Write-Output '##########################################################'
    Write-Output ' '
    Write-Output '             ***** Starting WIM Witch *****'
    Write-Output "                      version $WWScriptVer"
    Write-Output ' '
    Write-Output '##########################################################'
    Write-Output ' '
}

#Function to check suitability of the proposed mount point folder
Function Test-MountPath {
    param(
        [parameter(mandatory = $true, HelpMessage = 'mount path')]
        $path,

        [parameter(mandatory = $false, HelpMessage = 'clear out the crapola')]
        [ValidateSet($true)]
        $clean
    )


    $IsMountPoint = $null
    $HasFiles = $null
    $currentmounts = Get-WindowsImage -Mounted

    foreach ($currentmount in $currentmounts) {
        if ($currentmount.path -eq $path) { $IsMountPoint = $true }
    }

    if ($null -eq $IsMountPoint) {
        if ( (Get-ChildItem $path | Measure-Object).Count -gt 0) {
            $HasFiles = $true
        }
    }

    if ($HasFiles -eq $true) {
        Update-Log -Data 'Folder is not empty' -Class Warning
        if ($clean -eq $true) {
            try {
                Update-Log -Data 'Cleaning folder...' -Class Warning
                Remove-Item -Path $path\* -Recurse -Force -ErrorAction Stop
                Update-Log -Data "$path cleared" -Class Warning
            }

            catch {
                Update-Log -Data "Couldn't delete contents of $path" -Class Error
                Update-Log -Data 'Select a different folder to continue.' -Class Error
                return
            }
        }
    }

    if ($IsMountPoint -eq $true) {
        Update-Log -Data "$path is currently a mount point" -Class Warning
        if (($IsMountPoint -eq $true) -and ($clean -eq $true)) {

            try {
                Update-Log -Data 'Attempting to dismount image from mount point' -Class Warning
                Dismount-WindowsImage -Path $path -Discard | Out-Null -ErrorAction Stop
                $IsMountPoint = $null
                Update-Log -Data 'Dismounting was successful' -Class Warning
            }

            catch {
                Update-Log -Data "Couldn't completely dismount the folder. Ensure" -Class Error
                Update-Log -data 'all connections to the path are closed, then try again' -Class Error
                return
            }
        }
    }
    if (($null -eq $IsMountPoint) -and ($null -eq $HasFiles)) {
        Update-Log -Data "$path is suitable for mounting" -Class Information
    }
}

#Function to check the name of the target file and remediate if necessary
Function Test-Name {
    Param(
        [parameter(mandatory = $false, HelpMessage = 'what to do')]
        [ValidateSet('stop', 'append', 'backup', 'overwrite')]
        $conflict = 'stop'
    )

    If ($WPFMISWimNameTextBox.Text -like '*.wim') {
        #$WPFLogging.Focus()
        #Update-Log -Data "New WIM name is valid" -Class Information
    }

    If ($WPFMISWimNameTextBox.Text -notlike '*.wim') {

        $WPFMISWimNameTextBox.Text = $WPFMISWimNameTextBox.Text + '.wim'
        Update-Log -Data 'Appending new file name with an extension' -Class Information
    }

    $WIMpath = $WPFMISWimFolderTextBox.text + '\' + $WPFMISWimNameTextBox.Text
    $FileCheck = Test-Path -Path $WIMpath


    #append,overwrite,stop

    if ($FileCheck -eq $false) { Update-Log -data 'Target WIM file name not in use. Continuing...' -class Information }
    else {
        if ($conflict -eq 'append') {
            $renamestatus = (Rename-Name -file $WIMpath -extension '.wim')
            if ($renamestatus -eq 'stop') { return 'stop' }
        }
        if ($conflict -eq 'overwrite') {
            Write-Host 'overwrite action'
            return
        }
        if ($conflict -eq 'stop') {
            $string = $WPFMISWimNameTextBox.Text + ' already exists. Rename the target WIM and try again'
            Update-Log -Data $string -Class Warning
            return 'stop'
        }
    }
    Update-Log -Data 'New WIM name is valid' -Class Information
}

#Function to rename existing target wim file if the target WIM name already exists
Function Rename-Name($file, $extension) {
    $text = 'Renaming existing ' + $extension + ' file...'
    Update-Log -Data $text -Class Warning
    $filename = (Split-Path -Leaf $file)
    $dateinfo = (Get-Item -Path $file).LastWriteTime -replace (' ', '_') -replace ('/', '_') -replace (':', '_')
    $filename = $filename -replace ($extension, '')
    $filename = $filename + $dateinfo + $extension
    try {
        Rename-Item -Path $file -NewName $filename -ErrorAction Stop
        $text = $file + ' has been renamed to ' + $filename
        Update-Log -Data $text -Class Warning
    }
    catch {
        Update-Log -data "Couldn't rename file. Stopping..." -force -Class Error
        return 'stop'
    }
}

#Function to see if the folder WIM Witch was started in is an installation folder. If not, prompt for installation
Function Test-Install {

    Function select-installfolder {
        $installselect = New-Object System.Windows.Forms.FolderBrowserDialog
        $installselect.Description = 'Select the installation folder'
        $null = $installselect.ShowDialog()

        if ($installselect.SelectedPath -eq '') {
            Write-Output 'User Cancelled or invalid entry'
            exit 0
        }

        return $installselect.SelectedPath
    }

    Function install-wimwitch {
        Write-Output 'Would you like to install WIM Witch here?'
        $yesno = Read-Host -Prompt '(Y/N)'
        Write-Output $yesno
        if (($yesno -ne 'Y') -and ($yesno -ne 'N')) {
            Write-Output 'Invalid entry, try again.'
            install-wimwitch
        }

        if (($yesno -eq 'y') -and ($PSScriptRoot -notlike '*WindowsPowerShell\Scripts*')) {
            foreach ($subfolder in $subfolders) {
                New-Item -Path $subfolder -ItemType Directory | Out-Null
                Write-Output "Created folder: $subfolder"
            }
        }
        if (($yesno -eq 'y') -and ($PSScriptRoot -like '*WindowsPowerShell\Scripts*')) {
            Write-Output ' '
            Write-Output 'You cannot install WIM Witch in the script repository folder.'
            Write-Output "Also, you probably shouldn't install this in My Downloads, or My Desktop"
            Write-Output 'Please select another folder'
            $yesno = 'n'

        }
        if ($yesno -eq 'n') {
            Write-Output 'Select an installation folder'
            $installpath = select-installfolder

            if ($installpath -like '*WindowsPowerShell\Scripts*') {
                Write-Output 'You cannot install WIM Witch in the script repository folder'
                Write-Output 'Exiting installer. Please try again'
                exit 0
            }

            Write-Output "Installing WIM Witch in: $installpath"
            Copy-Item -Path $MyInvocation.ScriptName -Destination $installpath -Force
            Write-Output 'WIM Witch script copied to installation path'
            Set-Location -Path $installpath
            foreach ($subfolder in $subfolders) {

                if ((Test-Path -Path "$subfolder") -eq $true) { Write-Host "$subfolder exists" }
                if ((Test-Path -Path "$subfolder") -eq $false) {
                    New-Item -Path $subfolder -ItemType Directory | Out-Null
                    Write-Output "Created folder: $subfolder"
                }
            }

            Write-Output '============================================='
            Write-Output "WIM Witch has been installed to $installpath"
            Write-Output 'Start WIM witch from that folder to continue.'
            Write-Output ' '
            Write-Output 'Exiting...'
            break
        }
    }

    $subfolders = @(
        'CompletedWIMs'
        'Configs'
        'drivers'
        'jobs'
        'logging'
        'Mount'
        'Staging'
        'updates'
        'imports'
        'imports\WIM'
        'imports\DotNet'
        'Autopilot'
        'backup'
    )

    #    if ((Get-WmiObject win32_operatingsystem).version -like '10.0.*') { Write-Output "WIM Witch is running on a supported OS" }
    #    else {
    #        Write-Output "Current OS not supported"
    #        Write-Output "Please run WIM Witch on Windows 10 / Server 2016+"
    #        exit 0


    $count = $null
    Set-Location -Path $PSScriptRoot
    Write-Output "WIM Witch starting in $PSScriptRoot"
    Write-Output 'Checking for installation status'
    foreach ($subfolder in $subfolders) {
        if ((Test-Path -Path .\$subfolder) -eq $true) { $count = $count + 1 }
    }

    if ($null -eq $count) {
        Write-Output 'WIM Witch does not appear to be installed in this location.'
        install-wimwitch
    }
    if ($null -ne $count) {
        Write-Output 'WIM Witch is installed'
        Write-Output 'Remediating for missing folders if they exist'
        foreach ($subfolder in $subfolders) {

            if ((Test-Path -Path "$subfolder") -eq $false) {
                New-Item -Path $subfolder -ItemType Directory | Out-Null
                Write-Output "Created folder: $subfolder"
            }
        }
        Write-Output 'Preflight complete. Starting WIM Witch'
    }
}

Function Set-Version($wimversion) {
    if ($wimversion -like '10.0.16299.*') { $version = '1709' }
    if ($wimversion -like '10.0.17134.*') { $version = '1803' }
    if ($wimversion -like '10.0.17763.*') { $version = '1809' }
    if ($wimversion -like '10.0.18362.*') { $version = '1909' }
    if ($wimversion -like '10.0.14393.*') { $version = '1607' }
    if ($wimversion -like '10.0.19041.*') { $version = '2004' }
    if ($wimversion -like '10.0.22000.*') { $version = '21H2' }
    if ($wimversion -like '10.0.20348.*') { $version = '21H2' }
    if ($wimversion -like '10.0.22621.*') { $version = '22H2' }


    return $version
}


#Function Import-ISO($file, $type, $newname) {
Function Import-ISO {
    $newname = $WPFImportNewNameTextBox.Text
    $file = $WPFImportISOTextBox.Text

    #Check to see if destination WIM already exists

    if ($WPFImportWIMCheckBox.IsChecked -eq $true) {
        Update-Log -data 'Checking to see if the destination WIM file exists...' -Class Information
        #check to see if the new name for the imported WIM is valid
        if (($WPFImportNewNameTextBox.Text -eq '') -or ($WPFImportNewNameTextBox.Text -eq 'Name for the imported WIM')) {
            Update-Log -Data 'Enter a valid file name for the imported WIM and then try again' -Class Error
            return
        }

        If ($newname -notlike '*.wim') {
            $newname = $newname + '.wim'
            Update-Log -Data 'Appending new file name with an extension' -Class Information
        }

        if ((Test-Path -Path $PSScriptRoot\Imports\WIM\$newname) -eq $true) {
            Update-Log -Data 'Destination WIM name already exists. Provide a new name and try again.' -Class Error
            return
        }
        else {
            Update-Log -Data 'Name appears to be good. Continuing...' -Class Information
        }
    }

    #Mount ISO
    Update-Log -Data 'Mounting ISO...' -Class Information
    try {
        $isomount = Mount-DiskImage -ImagePath $file -PassThru -NoDriveLetter -ErrorAction Stop
        $iso = $isomount.devicepath

    }
    catch {
        Update-Log -Data 'Could not mount the ISO! Stopping actions...' -Class Error
        return
    }
    if (-not(Test-Path -Path (Join-Path $iso '\sources\'))) {
        Update-Log -Data 'Could not access the mounted ISO! Stopping actions...' -Class Error
        try {
            Invoke-RemoveISOMount -inputObject $isomount
        }
        catch {
            Update-Log -Data 'Attempted to dismount iso - might have failed...' -Class Warning
        }
        return
    }
    Update-Log -Data "$isomount" -Class Information
    #Testing for ESD or WIM format
    if (Test-Path -Path (Join-Path $iso '\sources\install.wim')) {
        $installWimFound = $true
    }
    elseif (Test-Path -Path (Join-Path $iso '\sources\install.esd')) {
        $installEsdFound = $true
        Update-Log -data 'Found ESD type installer - attempting to convert to WIM.' -Class Information
    }
    else {
        Update-Log -data 'Error accessing install.wim or install.esd! Breaking' -Class Warning
        try {
            Invoke-RemoveISOMount -inputObject $isomount
        }
        catch {
            Update-Log -Data 'Attempted to dismount iso - might have failed...' -Class Warning
        }
        return
    }

    try {
        if ($installWimFound) {
            $windowsver = Get-WindowsImage -ImagePath (Join-Path $iso '\sources\install.wim') -Index 1 -ErrorAction Stop
        }
        elseif ($installEsdFound) {
            $windowsver = Get-WindowsImage -ImagePath (Join-Path $iso '\sources\install.esd') -Index 1 -ErrorAction Stop
        }


        #####################
        #Right here
        $version = Set-Version -wimversion $windowsver.version

        if ($version -eq 2004) {
            $global:Win10VerDet = $null
            Invoke-19041Select
            if ($null -eq $global:Win10VerDet) {
                Write-Host 'cancelling'
                return
            }
            else {
                $version = $global:Win10VerDet
                $global:Win10VerDet = $null
            }

            if ($version -eq '20H2') { $version = '2009' }
            Write-Host $version
        }

    }
    catch {
        Update-Log -data 'install.wim could not be found or accessed! Skipping...' -Class Warning
        $installWimFound = $false
    }


    #Copy out WIM file
    #if (($type -eq "all") -or ($type -eq "wim")) {
    if (($WPFImportWIMCheckBox.IsChecked -eq $true) -and (($installWimFound) -or ($installEsdFound))) {

        #Copy out the WIM file from the selected ISO
        try {
            Update-Log -data 'Purging staging folder...' -Class Information
            Remove-Item -Path $PSScriptRoot\staging\*.* -Force
            Update-Log -data 'Purge complete.' -Class Information
            if ($installWimFound) {
                Update-Log -Data 'Copying WIM file to the staging folder...' -Class Information
                Copy-Item -Path $iso\sources\install.wim -Destination $PSScriptRoot\staging -Force -ErrorAction Stop -PassThru
            }
        }
        catch {
            Update-Log -data "Couldn't copy from the source" -Class Error
            Invoke-RemoveISOMount -inputObject $isomount
            return
        }

        #convert the ESD file to WIM
        if ($installEsdFound) {
            $sourceEsdFile = (Join-Path $iso '\sources\install.esd')
            Update-Log -Data 'Assessing install.esd file...' -Class Information
            $indexesFound = Get-WindowsImage -ImagePath $sourceEsdFile
            Update-Log -Data "$($indexesFound.Count) indexes found for conversion..." -Class Information
            foreach ($index in $indexesFound) {
                try {
                    Update-Log -Data "Converting index $($index.ImageIndex) - $($index.ImageName)" -Class Information
                    Export-WindowsImage -SourceImagePath $sourceEsdFile -SourceIndex $($index.ImageIndex) -DestinationImagePath (Join-Path $PSScriptRoot '\staging\install.wim') -CompressionType fast -ErrorAction Stop
                }
                catch {
                    Update-Log -Data "Converting index $($index.ImageIndex) failed - skipping..." -Class Error
                    continue
                }
            }
        }

        #Change file attribute to normal
        Update-Log -Data 'Setting file attribute of install.wim to Normal' -Class Information
        $attrib = Get-Item $PSScriptRoot\staging\install.wim
        $attrib.Attributes = 'Normal'

        #Rename install.wim to the new name
        try {
            $text = 'Renaming install.wim to ' + $newname
            Update-Log -Data $text -Class Information
            Rename-Item -Path $PSScriptRoot\Staging\install.wim -NewName $newname -ErrorAction Stop
        }
        catch {
            Update-Log -data "Couldn't rename the copied file. Most likely a weird permissions issues." -Class Error
            Invoke-RemoveISOMount -inputObject $isomount
            return
        }

        #Move the imported WIM to the imports folder

        try {
            Update-Log -data "Moving $newname to imports folder..." -Class Information
            Move-Item -Path $PSScriptRoot\Staging\$newname -Destination $PSScriptRoot\Imports\WIM -ErrorAction Stop
        }
        catch {
            Update-Log -Data "Couldn't move the new WIM to the staging folder." -Class Error
            Invoke-RemoveISOMount -inputObject $isomount
            return
        }
        Update-Log -data 'WIM importation complete' -Class Information
    }

    #Copy DotNet binaries

    if ($WPFImportDotNetCheckBox.IsChecked -eq $true) {


        If (($windowsver.imagename -like '*Windows 10*') -or (($windowsver.imagename -like '*server') -and ($windowsver.version -lt 10.0.20248.0))) { $Path = "$PSScriptRoot\Imports\DotNet\$version" }
        If (($windowsver.Imagename -like '*server*') -and ($windowsver.version -gt 10.0.20348.0)) { $Path = "$PSScriptRoot\Imports\Dotnet\Windows Server\$version" }
        If ($windowsver.imagename -like '*Windows 11*') { $Path = "$PSScriptRoot\Imports\Dotnet\Windows 11\$version" }


        if ((Test-Path -Path $Path) -eq $false) {

            try {
                Update-Log -Data 'Creating folders...' -Class Warning

                New-Item -Path (Split-Path -Path $path -Parent) -Name $version -ItemType Directory -ErrorAction stop | Out-Null

            }
            catch {
                Update-Log -Data "Couldn't creating new folder in DotNet imports folder" -Class Error
                return
            }
        }


        try {
            Update-Log -Data 'Copying .Net binaries...' -Class Information
            Copy-Item -Path $iso\sources\sxs\*netfx3* -Destination $path -Force -ErrorAction Stop

        }
        catch {
            Update-Log -Data "Couldn't copy the .Net binaries" -Class Error
            return
        }
    }

    #Copy out ISO files
    if ($WPFImportISOCheckBox.IsChecked -eq $true) {
        #Determine if is Windows 10 or Windows Server
        Update-Log -Data 'Importing ISO/Upgrade Package files...' -Class Information

        if ($windowsver.ImageName -like 'Windows 10*') { $OS = 'Windows 10' }

        if ($windowsver.ImageName -like 'Windows 11*') { $OS = 'Windows 11' }

        if ($windowsver.ImageName -like '*Server*') { $OS = 'Windows Server' }
        Update-Log -Data "$OS detected" -Class Information
        if ((Test-Path -Path $PSScriptRoot\imports\iso\$OS\$Version) -eq $false) {
            Update-Log -Data 'Path does not exist. Creating...' -Class Information
            New-Item -Path $PSScriptRoot\imports\iso\$OS\ -Name $version -ItemType Directory
        }

        Update-Log -Data 'Copying boot folder...' -Class Information
        Copy-Item -Path $iso\boot\ -Destination $PSScriptRoot\imports\iso\$OS\$Version\boot -Recurse -Force #-Exclude install.wim

        Update-Log -Data 'Copying efi folder...' -Class Information
        Copy-Item -Path $iso\efi\ -Destination $PSScriptRoot\imports\iso\$OS\$Version\efi -Recurse -Force #-Exclude install.wim

        Update-Log -Data 'Copying sources folder...' -Class Information
        Copy-Item -Path $iso\sources\ -Destination $PSScriptRoot\imports\iso\$OS\$Version\sources -Recurse -Force -Exclude install.wim

        Update-Log -Data 'Copying support folder...' -Class Information
        Copy-Item -Path $iso\support\ -Destination $PSScriptRoot\imports\iso\$OS\$Version\support -Recurse -Force #-Exclude install.wim

        Update-Log -Data 'Copying files in root folder...' -Class Information
        Copy-Item $iso\autorun.inf -Destination $PSScriptRoot\imports\iso\$OS\$Version\ -Force
        Copy-Item $iso\bootmgr -Destination $PSScriptRoot\imports\iso\$OS\$Version\ -Force
        Copy-Item $iso\bootmgr.efi -Destination $PSScriptRoot\imports\iso\$OS\$Version\ -Force
        Copy-Item $iso\setup.exe -Destination $PSScriptRoot\imports\iso\$OS\$Version\ -Force

    }

    #Dismount and finish
    try {
        Update-Log -Data 'Dismount!' -Class Information
        Invoke-RemoveISOMount -inputObject $isomount
    }
    catch {
        Update-Log -Data "Couldn't dismount the ISO. WIM Witch uses a file mount option that does not" -Class Error
        Update-Log -Data 'provision a drive letter. Use the Dismount-DiskImage command to manaully dismount.' -Class Error
    }
    Update-Log -data 'Importing complete' -class Information
}

#Function to select ISO for import
Function Select-ISO {

    $SourceISO = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'ISO (*.iso)|'
    }
    $null = $SourceISO.ShowDialog()
    $WPFImportISOTextBox.text = $SourceISO.FileName


    if ($SourceISO.FileName -notlike '*.iso') {
        Update-Log -Data 'An ISO file not selected. Please select a valid file to continue.' -Class Warning
        return
    }
    $text = $WPFImportISOTextBox.text + ' selected as the ISO to import from'
    Update-Log -Data $text -class Information

}

#Function to inject the .Net 3.5 binaries from the import folder
Function Add-DotNet {

    $buildnum = Get-WinVersionNumber
    $OSType = Get-WindowsType

    #fix the build number 21h

    if ($OSType -eq 'Windows 10') { $DotNetFiles = "$PSScriptRoot\imports\DotNet\$buildnum" }
    if (($OSType -eq 'Windows 11') -or ($OSType -eq 'Windows Server')) { $DotNetFiles = "$PSScriptRoot\imports\DotNet\$OSType\$buildnum" }


    try {
        $text = 'Injecting .Net 3.5 binaries from ' + $DotNetFiles
        Update-Log -Data $text -Class Information
        Add-WindowsPackage -PackagePath $DotNetFiles -Path $WPFMISMountTextBox.Text -ErrorAction Continue | Out-Null
    }
    catch {
        Update-Log -Data "Couldn't inject .Net Binaries" -Class Warning
        Update-Log -data $_.Exception.Message -Class Error
        return
    }
    Update-Log -Data '.Net 3.5 injection complete' -Class Information
}

#Function to see if the .Net binaries for the select Win10 version exist
Function Test-DotNetExists {

    $OSType = Get-WindowsType
    #$buildnum = Get-WinVersionNumber
    $buildnum = $WPFSourceWimTBVersionNum.text

    if ($OSType -eq 'Windows 10') {
        if ($buildnum -eq '20H2') { $Buildnum = '2009' }
        $DotNetFiles = "$PSScriptRoot\imports\DotNet\$buildnum"
    }
    if (($OSType -eq 'Windows 11') -or ($OSType -eq 'Windows Server')) { $DotNetFiles = "$PSScriptRoot\imports\DotNet\$OSType\$buildnum" }


    Test-Path -Path $DotNetFiles\*
    if ((Test-Path -Path $DotNetFiles\*) -eq $false) {
        $text = '.Net 3.5 Binaries are not present for ' + $buildnum
        Update-Log -Data $text -Class Warning
        Update-Log -data 'Import .Net from an ISO or disable injection to continue' -Class Warning
        return $false
    }
}

#For those who like to dig through code and find notes from the dev team:
#Each Function is listed in the order it was created. This point marks
#where v1.0 was released. Everything
#below is from updates -DRR 10/22/2020

Function Install-WimWitchUpgrade {
    Write-Output 'Would you like to upgrade WIM Witch?'
    $yesno = Read-Host -Prompt '(Y/N)'
    Write-Output $yesno
    if (($yesno -ne 'Y') -and ($yesno -ne 'N')) {
        Write-Output 'Invalid entry, try again.'
        Install-WimWitchUpgrade
    }

    if ($yesno -eq 'y') {
        Backup-WIMWitch

        try {
            Save-Script -Name 'WIMWitch' -Path $PSScriptRoot -Force -ErrorAction Stop
            Write-Output 'New version has been applied. WIM Witch will now exit.'
            Write-Output 'Please restart WIM Witch'
            exit
        }
        catch {
            Write-Output "Couldn't upgrade. Try again when teh tubes are clear"
            return
        }

    }


    if ($yesno -eq 'n') {
        Write-Output "You'll want to upgrade at some point."
        Update-Log -Data 'Upgrade to new version was declined' -Class Warning
        Update-Log -Data 'Continuing to start WIM Witch...' -Class Warning
    }

}


#Function to check installed version of WIM Witch and update if available
Function Test-WIMWitchVer {
    Update-Log -Data "The currently installed version of WIM Witch is $WWScriptVer" -Class Information
    Update-Log -data 'Checking for updates from PowerShell Gallery...' -Class Information


    try {
        $WWCurrentVer = (Find-Script -Name 'WIMWitch' -ErrorAction Stop).version
        Update-Log -Data "The latest version from the Gallery is $WWCurrentVer" -Class Information
    }
    catch {
        Update-Log -Data "Couldn't retreive script info from the PowerShell Gallery" -Class Warning
        Update-Log -data 'Try rebooting the internet and trying again' -Class Warning
        Update-Log -data 'Continuing on with loading WIM Witch...' -Class Warning
        return
    }


    If (($WWCurrentVer -gt $WWScriptVer) -and ($auto -eq $false)) { Install-WimWitchUpgrade }
    if (($WWCurrentVer -gt $WWScriptVer) -and ($auto -eq $true)) { Update-Log -data 'Skipping WIM Witch upgrade because she is in auto-mode. Please launch WIM Witch in GUI mode to update.' -class warning }
    If ($WWCurrentVer -eq $WWScriptVer) { Update-Log -data 'WIM Witch is up to date. Starting WIM Witch' -Class Information }
    If ($WWCurrentVer -lt $WWScriptVer) {
        Update-Log -Data 'The local copy of WIM Witch is more current that the most current' -class Warning
        Update-Log -Data 'version available. Did you violate the Temporal Prime Directive?' -class Warning
        Update-Log -data 'Starting WIM Witch anyway...' -class warning

    }

}

#Function to backup WIM Witch script file during upgrade
Function Backup-WIMWitch {
    Update-log -data 'Backing up existing WIM Witch script...' -Class Information

    $scriptname = Split-Path $MyInvocation.PSCommandPath -Leaf #Find local script name
    Update-Log -data 'The script to be backed up is: ' -Class Information
    Update-Log -data $MyInvocation.PSCommandPath -Class Information

    try {
        Update-Log -data 'Copy script to backup folder...' -Class Information
        Copy-Item -Path $scriptname -Destination $PSScriptRoot\backup -ErrorAction Stop
        Update-Log -Data 'Successfully copied...' -Class Information
    }
    catch {
        Update-Log -data "Couldn't copy the WIM Witch script. My guess is a permissions issue" -Class Error
        Update-Log -Data 'Exiting out of an over abundance of caution' -Class Error
        exit
    }

    try {
        Update-Log -data 'Renaming archived script...' -Class Information
        Rename-Name -file $PSScriptRoot\backup\$scriptname -extension '.ps1'
        Update-Log -data 'Backup successfully renamed for archiving' -class Information
    }
    catch {

        Update-Log -Data "Backed-up script couldn't be renamed. This isn't a critical error" -Class Warning
        Update-Log -Data "You may want to change it's name so it doesn't get overwritten." -Class Warning
        Update-Log -Data 'Continuing with WIM Witch upgrade...' -Class Warning
    }
}

#Function to download current OneDrive client
#Most of this was stolen from David Segura @SeguraOSD
Function Get-OneDrive {
    #https://go.microsoft.com/fwlink/p/?LinkID=844652 -Possible new link location.
    #https://go.microsoft.com/fwlink/?linkid=2181064 - x64 installer


    Update-Log -Data 'Downloading latest 32-bit OneDrive agent installer...' -class Information
    $DownloadUrl = 'https://go.microsoft.com/fwlink/p/?LinkId=248256'
    $DownloadPath = "$PSScriptRoot\updates\OneDrive"
    $DownloadFile = 'OneDriveSetup.exe'

    if (!(Test-Path "$DownloadPath")) { New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "$DownloadPath\$DownloadFile"
    if (Test-Path "$DownloadPath\$DownloadFile") {
        Update-Log -Data 'OneDrive Download Complete' -Class Information
    }
    else {
        Update-log -Data 'OneDrive could not be downloaded' -Class Error
    }


    Update-Log -Data 'Downloading latest 64-bit OneDrive agent installer...' -class Information
    $DownloadUrl = 'https://go.microsoft.com/fwlink/?linkid=2181064'
    $DownloadPath = "$PSScriptRoot\updates\OneDrive\x64"
    $DownloadFile = 'OneDriveSetup.exe'

    if (!(Test-Path "$DownloadPath")) { New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "$DownloadPath\$DownloadFile"
    if (Test-Path "$DownloadPath\$DownloadFile") {
        Update-Log -Data 'OneDrive Download Complete' -Class Information
    }
    else {
        Update-log -Data 'OneDrive could not be downloaded' -Class Error
    }

}

#Function to copy new OneDrive client installer to mount path
Function Copy-OneDrive {
    Update-Log -data 'Updating OneDrive x86 client' -class information
    try {
        Update-Log -Data 'Setting ACL on the original OneDriveSetup.exe file' -Class Information
        $mountpath = $WPFMISMountTextBox.text

        $AclBAK = Get-Acl "$mountpath\Windows\SysWOW64\OneDriveSetup.exe"
        $user = $env:USERDOMAIN + '\' + $env:USERNAME
        $Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $user
        $item = Get-Item "$mountpath\Windows\SysWOW64\OneDriveSetup.exe"

        $Acl = $null # Reset the $Acl variable to $null
        $Acl = Get-Acl -Path $Item.FullName # Get the ACL from the item
        $Acl.SetOwner($Account) # Update the in-memory ACL
        Set-Acl -Path $Item.FullName -AclObject $Acl -ErrorAction Stop  # Set the updated ACL on the target item
        Update-Log -Data 'Ownership of OneDriveSetup.exe siezed' -Class Information

        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'FullControl', 'Allow')
        $Acl.SetAccessRule($Ar)
        Set-Acl "$mountpath\Windows\SysWOW64\OneDriveSetup.exe" $Acl -ErrorAction Stop | Out-Null

        Update-Log -Data 'ACL successfully updated. Continuing...'
    }
    catch {
        Update-Log -data "Couldn't set the ACL on the original file" -Class Error
        return
    }

    try {


        Update-Log -data 'Copying updated OneDrive agent installer...' -Class Information
        Copy-Item "$PSScriptRoot\updates\OneDrive\OneDriveSetup.exe" -Destination "$mountpath\Windows\SysWOW64" -Force -ErrorAction Stop
        Update-Log -Data 'OneDrive installer successfully copied.' -Class Information
    }
    catch {
        Update-Log -data "Couldn't copy the OneDrive installer file." -class Error
        Update-Log -data $_.Exception.Message -Class Error
        return
    }

    try {
        Update-Log -data 'Restoring original ACL to OneDrive installer.' -Class Information
        Set-Acl "$mountpath\Windows\SysWOW64\OneDriveSetup.exe" $AclBAK -ErrorAction Stop | Out-Null
        Update-Log -data 'Restoration complete' -Class Information
    }
    catch {
        Update-Log "Couldn't restore original ACLs. Continuing." -Class Error
    }
}

#Function to copy new OneDrive client installer to mount path
Function Copy-OneDrivex64 {
    Update-Log -data 'Updating OneDrive x64 client' -class information
    try {
        Update-Log -Data 'Setting ACL on the original OneDriveSetup.exe file' -Class Information
        $mountpath = $WPFMISMountTextBox.text

        $AclBAK = Get-Acl "$mountpath\Windows\System32\OneDriveSetup.exe"
        $user = $env:USERDOMAIN + '\' + $env:USERNAME
        $Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $user
        $item = Get-Item "$mountpath\Windows\System32\OneDriveSetup.exe"

        $Acl = $null # Reset the $Acl variable to $null
        $Acl = Get-Acl -Path $Item.FullName # Get the ACL from the item
        $Acl.SetOwner($Account) # Update the in-memory ACL
        Set-Acl -Path $Item.FullName -AclObject $Acl -ErrorAction Stop  # Set the updated ACL on the target item
        Update-Log -Data 'Ownership of OneDriveSetup.exe siezed' -Class Information

        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'FullControl', 'Allow')
        $Acl.SetAccessRule($Ar)
        Set-Acl "$mountpath\Windows\System32\OneDriveSetup.exe" $Acl -ErrorAction Stop | Out-Null

        Update-Log -Data 'ACL successfully updated. Continuing...'
    }
    catch {
        Update-Log -data "Couldn't set the ACL on the original file" -Class Error
        return
    }

    try {

        Update-Log -data 'Copying updated OneDrive agent installer...' -Class Information
        Copy-Item "$PSScriptRoot\updates\OneDrive\x64\OneDriveSetup.exe" -Destination "$mountpath\Windows\System32" -Force -ErrorAction Stop
        Update-Log -Data 'OneDrive installer successfully copied.' -Class Information
    }
    catch {
        Update-Log -data "Couldn't copy the OneDrive installer file." -class Error
        Update-Log -data $_.Exception.Message -Class Error
        return
    }

    try {
        Update-Log -data 'Restoring original ACL to OneDrive installer.' -Class Information
        Set-Acl "$mountpath\Windows\System32\OneDriveSetup.exe" $AclBAK -ErrorAction Stop | Out-Null
        Update-Log -data 'Restoration complete' -Class Information
    }
    catch {
        Update-Log "Couldn't restore original ACLs. Continuing." -Class Error
    }
}

#Function to call the next three Functions. This determines WinOS and WinVer and calls the Function
Function Select-LPFODCriteria($Type) {

    $WinOS = Get-WindowsType
    #$WinVer = Get-WinVersionNumber
    $WinVer = $WPFSourceWimTBVersionNum.text

    if ($WinOS -eq 'Windows 10') {
        if (($Winver -eq '2009') -or ($winver -eq '20H2') -or ($winver -eq '21H1') -or ($winver -eq '21H2') -or ($winver -eq '22H2')) { $winver = '2004' }
    }

    if ($type -eq 'LP') {
        if ((Test-Path -Path $PSScriptRoot\imports\Lang\$WinOS\$Winver\LanguagePacks) -eq $false) {
            Update-Log -Data 'Source not found. Please import some language packs and try again' -Class Error
            return
        }
        Select-LanguagePacks -winver $Winver -WinOS $WinOS
    }

    If ($type -eq 'LXP') {
        if ((Test-Path -Path $PSScriptRoot\imports\Lang\$WinOS\$Winver\localexperiencepack) -eq $false) {
            Update-Log -Data 'Source not found. Please import some Local Experience Packs and try again' -Class Error
            return
        }
        Select-LocalExperiencePack -winver $Winver -WinOS $WinOS
    }

    if ($type -eq 'FOD') {
        if ((Test-Path -Path $PSScriptRoot\imports\FODs\$WinOS\$Winver\) -eq $false) {

            Update-Log -Data 'Source not found. Please import some Demanding Features and try again' -Class Error
            return
        }

        Select-FeaturesOnDemand -winver $Winver -WinOS $WinOS
    }
}

#Function to select langauge packs for injection
Function Select-LanguagePacks($winver, $WinOS) {

    $LPSourceFolder = $PSScriptRoot + '\imports\lang\' + $WinOS + '\' + $winver + '\' + 'LanguagePacks' + '\'

    $items = (Get-ChildItem -Path $LPSourceFolder | Select-Object -Property Name | Out-GridView -Title 'Select Language Packs' -PassThru)
    foreach ($item in $items) { $WPFCustomLBLangPacks.Items.Add($item.name) }
}

#Function to select LXP packs for injection
Function Select-LocalExperiencePack($winver, $WinOS) {

    $LPSourceFolder = $PSScriptRoot + '\imports\lang\' + $WinOS + '\' + $winver + '\' + 'localexperiencepack' + '\'


    $items = (Get-ChildItem -Path $LPSourceFolder | Select-Object -Property Name | Out-GridView -Title 'Select Local Experience Packs' -PassThru)
    foreach ($item in $items) { $WPFCustomLBLEP.Items.Add($item.name) }
}
#Hey Donna
#Function to select FODs for injection
Function Select-FeaturesOnDemand($winver, $WinOS) {
    $Win10_1909_FODs = @('Accessibility.Braille~~~~0.0.1.0',
        'Analog.Holographic.Desktop~~~~0.0.1.0',
        'App.Support.QuickAssist~~~~0.0.1.0',
        'Browser.InternetExplorer~~~~0.0.11.0',
        'Hello.Face.18330~~~~0.0.1.0',
        'Hello.Face.Migration.18330~~~~0.0.1.0',
        'Language.Basic~~~af-ZA~0.0.1.0',
        'Language.Basic~~~ar-SA~0.0.1.0',
        'Language.Basic~~~as-IN~0.0.1.0',
        'Language.Basic~~~az-LATN-AZ~0.0.1.0',
        'Language.Basic~~~ba-RU~0.0.1.0',
        'Language.Basic~~~be-BY~0.0.1.0',
        'Language.Basic~~~bg-BG~0.0.1.0',
        'Language.Basic~~~bn-BD~0.0.1.0',
        'Language.Basic~~~bn-IN~0.0.1.0',
        'Language.Basic~~~bs-LATN-BA~0.0.1.0',
        'Language.Basic~~~ca-ES~0.0.1.0',
        'Language.Basic~~~cs-CZ~0.0.1.0',
        'Language.Basic~~~cy-GB~0.0.1.0',
        'Language.Basic~~~da-DK~0.0.1.0',
        'Language.Basic~~~de-CH~0.0.1.0',
        'Language.Basic~~~de-DE~0.0.1.0',
        'Language.Basic~~~el-GR~0.0.1.0',
        'Language.Basic~~~en-AU~0.0.1.0',
        'Language.Basic~~~en-CA~0.0.1.0',
        'Language.Basic~~~en-GB~0.0.1.0',
        'Language.Basic~~~en-IN~0.0.1.0',
        'Language.Basic~~~en-US~0.0.1.0',
        'Language.Basic~~~es-ES~0.0.1.0',
        'Language.Basic~~~es-MX~0.0.1.0',
        'Language.Basic~~~es-US~0.0.1.0',
        'Language.Basic~~~et-EE~0.0.1.0',
        'Language.Basic~~~eu-ES~0.0.1.0',
        'Language.Basic~~~fa-IR~0.0.1.0',
        'Language.Basic~~~fi-FI~0.0.1.0',
        'Language.Basic~~~fil-PH~0.0.1.0',
        'Language.Basic~~~fr-BE~0.0.1.0',
        'Language.Basic~~~fr-CA~0.0.1.0',
        'Language.Basic~~~fr-CH~0.0.1.0',
        'Language.Basic~~~fr-FR~0.0.1.0',
        'Language.Basic~~~ga-IE~0.0.1.0',
        'Language.Basic~~~gd-GB~0.0.1.0',
        'Language.Basic~~~gl-ES~0.0.1.0',
        'Language.Basic~~~gu-IN~0.0.1.0',
        'Language.Basic~~~ha-LATN-NG~0.0.1.0',
        'Language.Basic~~~haw-US~0.0.1.0',
        'Language.Basic~~~he-IL~0.0.1.0',
        'Language.Basic~~~hi-IN~0.0.1.0',
        'Language.Basic~~~hr-HR~0.0.1.0',
        'Language.Basic~~~hu-HU~0.0.1.0',
        'Language.Basic~~~hy-AM~0.0.1.0',
        'Language.Basic~~~id-ID~0.0.1.0',
        'Language.Basic~~~ig-NG~0.0.1.0',
        'Language.Basic~~~is-IS~0.0.1.0',
        'Language.Basic~~~it-IT~0.0.1.0',
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Basic~~~ka-GE~0.0.1.0',
        'Language.Basic~~~kk-KZ~0.0.1.0',
        'Language.Basic~~~kl-GL~0.0.1.0',
        'Language.Basic~~~kn-IN~0.0.1.0',
        'Language.Basic~~~ko-KR~0.0.1.0',
        'Language.Basic~~~kok-DEVA-IN~0.0.1.0',
        'Language.Basic~~~ky-KG~0.0.1.0',
        'Language.Basic~~~lb-LU~0.0.1.0',
        'Language.Basic~~~lt-LT~0.0.1.0',
        'Language.Basic~~~lv-LV~0.0.1.0',
        'Language.Basic~~~mi-NZ~0.0.1.0',
        'Language.Basic~~~mk-MK~0.0.1.0',
        'Language.Basic~~~ml-IN~0.0.1.0',
        'Language.Basic~~~mn-MN~0.0.1.0',
        'Language.Basic~~~mr-IN~0.0.1.0',
        'Language.Basic~~~ms-BN~0.0.1.0',
        'Language.Basic~~~ms-MY~0.0.1.0',
        'Language.Basic~~~mt-MT~0.0.1.0',
        'Language.Basic~~~nb-NO~0.0.1.0',
        'Language.Basic~~~ne-NP~0.0.1.0',
        'Language.Basic~~~nl-NL~0.0.1.0',
        'Language.Basic~~~nn-NO~0.0.1.0',
        'Language.Basic~~~nso-ZA~0.0.1.0',
        'Language.Basic~~~or-IN~0.0.1.0',
        'Language.Basic~~~pa-IN~0.0.1.0',
        'Language.Basic~~~pl-PL~0.0.1.0',
        'Language.Basic~~~ps-AF~0.0.1.0',
        'Language.Basic~~~pt-BR~0.0.1.0',
        'Language.Basic~~~pt-PT~0.0.1.0',
        'Language.Basic~~~rm-CH~0.0.1.0',
        'Language.Basic~~~ro-RO~0.0.1.0',
        'Language.Basic~~~ru-RU~0.0.1.0',
        'Language.Basic~~~rw-RW~0.0.1.0',
        'Language.Basic~~~sah-RU~0.0.1.0',
        'Language.Basic~~~si-LK~0.0.1.0',
        'Language.Basic~~~sk-SK~0.0.1.0',
        'Language.Basic~~~sl-SI~0.0.1.0',
        'Language.Basic~~~sq-AL~0.0.1.0',
        'Language.Basic~~~sr-CYRL-RS~0.0.1.0',
        'Language.Basic~~~sr-LATN-RS~0.0.1.0',
        'Language.Basic~~~sv-SE~0.0.1.0',
        'Language.Basic~~~sw-KE~0.0.1.0',
        'Language.Basic~~~ta-IN~0.0.1.0',
        'Language.Basic~~~te-IN~0.0.1.0',
        'Language.Basic~~~tg-CYRL-TJ~0.0.1.0',
        'Language.Basic~~~th-TH~0.0.1.0',
        'Language.Basic~~~tk-TM~0.0.1.0',
        'Language.Basic~~~tn-ZA~0.0.1.0',
        'Language.Basic~~~tr-TR~0.0.1.0',
        'Language.Basic~~~tt-RU~0.0.1.0',
        'Language.Basic~~~ug-CN~0.0.1.0',
        'Language.Basic~~~uk-UA~0.0.1.0',
        'Language.Basic~~~ur-PK~0.0.1.0',
        'Language.Basic~~~uz-LATN-UZ~0.0.1.0',
        'Language.Basic~~~vi-VN~0.0.1.0',
        'Language.Basic~~~wo-SN~0.0.1.0',
        'Language.Basic~~~xh-ZA~0.0.1.0',
        'Language.Basic~~~yo-NG~0.0.1.0',
        'Language.Basic~~~zh-CN~0.0.1.0',
        'Language.Basic~~~zh-HK~0.0.1.0',
        'Language.Basic~~~zh-TW~0.0.1.0',
        'Language.Basic~~~zu-ZA~0.0.1.0',
        'Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Beng~~~und-BENG~0.0.1.0',
        'Language.Fonts.Cans~~~und-CANS~0.0.1.0',
        'Language.Fonts.Cher~~~und-CHER~0.0.1.0',
        'Language.Fonts.Deva~~~und-DEVA~0.0.1.0',
        'Language.Fonts.Ethi~~~und-ETHI~0.0.1.0',
        'Language.Fonts.Gujr~~~und-GUJR~0.0.1.0',
        'Language.Fonts.Guru~~~und-GURU~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Hebr~~~und-HEBR~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Khmr~~~und-KHMR~0.0.1.0',
        'Language.Fonts.Knda~~~und-KNDA~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Laoo~~~und-LAOO~0.0.1.0',
        'Language.Fonts.Mlym~~~und-MLYM~0.0.1.0',
        'Language.Fonts.Orya~~~und-ORYA~0.0.1.0',
        'Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0',
        'Language.Fonts.Sinh~~~und-SINH~0.0.1.0',
        'Language.Fonts.Syrc~~~und-SYRC~0.0.1.0',
        'Language.Fonts.Taml~~~und-TAML~0.0.1.0',
        'Language.Fonts.Telu~~~und-TELU~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0',
        'Language.Handwriting~~~af-ZA~0.0.1.0',
        'Language.Handwriting~~~bs-LATN-BA~0.0.1.0',
        'Language.Handwriting~~~ca-ES~0.0.1.0',
        'Language.Handwriting~~~cs-CZ~0.0.1.0',
        'Language.Handwriting~~~cy-GB~0.0.1.0',
        'Language.Handwriting~~~da-DK~0.0.1.0',
        'Language.Handwriting~~~de-DE~0.0.1.0',
        'Language.Handwriting~~~el-GR~0.0.1.0',
        'Language.Handwriting~~~en-GB~0.0.1.0',
        'Language.Handwriting~~~en-US~0.0.1.0',
        'Language.Handwriting~~~es-ES~0.0.1.0',
        'Language.Handwriting~~~es-MX~0.0.1.0',
        'Language.Handwriting~~~eu-ES~0.0.1.0',
        'Language.Handwriting~~~fi-FI~0.0.1.0',
        'Language.Handwriting~~~fr-FR~0.0.1.0',
        'Language.Handwriting~~~ga-IE~0.0.1.0',
        'Language.Handwriting~~~gd-GB~0.0.1.0',
        'Language.Handwriting~~~gl-ES~0.0.1.0',
        'Language.Handwriting~~~hi-IN~0.0.1.0',
        'Language.Handwriting~~~hr-HR~0.0.1.0',
        'Language.Handwriting~~~id-ID~0.0.1.0',
        'Language.Handwriting~~~it-IT~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.Handwriting~~~ko-KR~0.0.1.0',
        'Language.Handwriting~~~lb-LU~0.0.1.0',
        'Language.Handwriting~~~mi-NZ~0.0.1.0',
        'Language.Handwriting~~~ms-BN~0.0.1.0',
        'Language.Handwriting~~~ms-MY~0.0.1.0',
        'Language.Handwriting~~~nb-NO~0.0.1.0',
        'Language.Handwriting~~~nl-NL~0.0.1.0',
        'Language.Handwriting~~~nn-NO~0.0.1.0',
        'Language.Handwriting~~~nso-ZA~0.0.1.0',
        'Language.Handwriting~~~pl-PL~0.0.1.0',
        'Language.Handwriting~~~pt-BR~0.0.1.0',
        'Language.Handwriting~~~pt-PT~0.0.1.0',
        'Language.Handwriting~~~rm-CH~0.0.1.0',
        'Language.Handwriting~~~ro-RO~0.0.1.0',
        'Language.Handwriting~~~ru-RU~0.0.1.0',
        'Language.Handwriting~~~rw-RW~0.0.1.0',
        'Language.Handwriting~~~sk-SK~0.0.1.0',
        'Language.Handwriting~~~sl-SI~0.0.1.0',
        'Language.Handwriting~~~sq-AL~0.0.1.0',
        'Language.Handwriting~~~sr-CYRL-RS~0.0.1.0',
        'Language.Handwriting~~~sr-LATN-RS~0.0.1.0',
        'Language.Handwriting~~~sv-SE~0.0.1.0',
        'Language.Handwriting~~~sw-KE~0.0.1.0',
        'Language.Handwriting~~~tn-ZA~0.0.1.0',
        'Language.Handwriting~~~tr-TR~0.0.1.0',
        'Language.Handwriting~~~wo-SN~0.0.1.0',
        'Language.Handwriting~~~xh-ZA~0.0.1.0',
        'Language.Handwriting~~~zh-CN~0.0.1.0',
        'Language.Handwriting~~~zh-HK~0.0.1.0',
        'Language.Handwriting~~~zh-TW~0.0.1.0',
        'Language.Handwriting~~~zu-ZA~0.0.1.0',
        'Language.OCR~~~ar-SA~0.0.1.0',
        'Language.OCR~~~bg-BG~0.0.1.0',
        'Language.OCR~~~bs-LATN-BA~0.0.1.0',
        'Language.OCR~~~cs-CZ~0.0.1.0',
        'Language.OCR~~~da-DK~0.0.1.0',
        'Language.OCR~~~de-DE~0.0.1.0',
        'Language.OCR~~~el-GR~0.0.1.0',
        'Language.OCR~~~en-GB~0.0.1.0',
        'Language.OCR~~~en-US~0.0.1.0',
        'Language.OCR~~~es-ES~0.0.1.0',
        'Language.OCR~~~es-MX~0.0.1.0',
        'Language.OCR~~~fi-FI~0.0.1.0',
        'Language.OCR~~~fr-CA~0.0.1.0',
        'Language.OCR~~~fr-FR~0.0.1.0',
        'Language.OCR~~~hr-HR~0.0.1.0',
        'Language.OCR~~~hu-HU~0.0.1.0',
        'Language.OCR~~~it-IT~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ko-KR~0.0.1.0',
        'Language.OCR~~~nb-NO~0.0.1.0',
        'Language.OCR~~~nl-NL~0.0.1.0',
        'Language.OCR~~~pl-PL~0.0.1.0',
        'Language.OCR~~~pt-BR~0.0.1.0',
        'Language.OCR~~~pt-PT~0.0.1.0',
        'Language.OCR~~~ro-RO~0.0.1.0',
        'Language.OCR~~~ru-RU~0.0.1.0',
        'Language.OCR~~~sk-SK~0.0.1.0',
        'Language.OCR~~~sl-SI~0.0.1.0',
        'Language.OCR~~~sr-CYRL-RS~0.0.1.0',
        'Language.OCR~~~sr-LATN-RS~0.0.1.0',
        'Language.OCR~~~sv-SE~0.0.1.0',
        'Language.OCR~~~tr-TR~0.0.1.0',
        'Language.OCR~~~zh-CN~0.0.1.0',
        'Language.OCR~~~zh-HK~0.0.1.0',
        'Language.OCR~~~zh-TW~0.0.1.0',
        'Language.Speech~~~da-DK~0.0.1.0',
        'Language.Speech~~~de-DE~0.0.1.0',
        'Language.Speech~~~en-AU~0.0.1.0',
        'Language.Speech~~~en-CA~0.0.1.0',
        'Language.Speech~~~en-GB~0.0.1.0',
        'Language.Speech~~~en-IN~0.0.1.0',
        'Language.Speech~~~en-US~0.0.1.0',
        'Language.Speech~~~es-ES~0.0.1.0',
        'Language.Speech~~~es-MX~0.0.1.0',
        'Language.Speech~~~fr-CA~0.0.1.0',
        'Language.Speech~~~fr-FR~0.0.1.0',
        'Language.Speech~~~it-IT~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.Speech~~~pt-BR~0.0.1.0',
        'Language.Speech~~~zh-CN~0.0.1.0',
        'Language.Speech~~~zh-HK~0.0.1.0',
        'Language.Speech~~~zh-TW~0.0.1.0',
        'Language.TextToSpeech~~~ar-EG~0.0.1.0',
        'Language.TextToSpeech~~~ar-SA~0.0.1.0',
        'Language.TextToSpeech~~~bg-BG~0.0.1.0',
        'Language.TextToSpeech~~~ca-ES~0.0.1.0',
        'Language.TextToSpeech~~~cs-CZ~0.0.1.0',
        'Language.TextToSpeech~~~da-DK~0.0.1.0',
        'Language.TextToSpeech~~~de-AT~0.0.1.0',
        'Language.TextToSpeech~~~de-CH~0.0.1.0',
        'Language.TextToSpeech~~~de-DE~0.0.1.0',
        'Language.TextToSpeech~~~el-GR~0.0.1.0',
        'Language.TextToSpeech~~~en-AU~0.0.1.0',
        'Language.TextToSpeech~~~en-CA~0.0.1.0',
        'Language.TextToSpeech~~~en-GB~0.0.1.0',
        'Language.TextToSpeech~~~en-IE~0.0.1.0',
        'Language.TextToSpeech~~~en-IN~0.0.1.0',
        'Language.TextToSpeech~~~en-US~0.0.1.0',
        'Language.TextToSpeech~~~es-ES~0.0.1.0',
        'Language.TextToSpeech~~~es-MX~0.0.1.0',
        'Language.TextToSpeech~~~fi-FI~0.0.1.0',
        'Language.TextToSpeech~~~fr-CA~0.0.1.0',
        'Language.TextToSpeech~~~fr-CH~0.0.1.0',
        'Language.TextToSpeech~~~fr-FR~0.0.1.0',
        'Language.TextToSpeech~~~he-IL~0.0.1.0',
        'Language.TextToSpeech~~~hi-IN~0.0.1.0',
        'Language.TextToSpeech~~~hr-HR~0.0.1.0',
        'Language.TextToSpeech~~~hu-HU~0.0.1.0',
        'Language.TextToSpeech~~~id-ID~0.0.1.0',
        'Language.TextToSpeech~~~it-IT~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ko-KR~0.0.1.0',
        'Language.TextToSpeech~~~ms-MY~0.0.1.0',
        'Language.TextToSpeech~~~nb-NO~0.0.1.0',
        'Language.TextToSpeech~~~nl-BE~0.0.1.0',
        'Language.TextToSpeech~~~nl-NL~0.0.1.0',
        'Language.TextToSpeech~~~pl-PL~0.0.1.0',
        'Language.TextToSpeech~~~pt-BR~0.0.1.0',
        'Language.TextToSpeech~~~pt-PT~0.0.1.0',
        'Language.TextToSpeech~~~ro-RO~0.0.1.0',
        'Language.TextToSpeech~~~ru-RU~0.0.1.0',
        'Language.TextToSpeech~~~sk-SK~0.0.1.0',
        'Language.TextToSpeech~~~sl-SI~0.0.1.0',
        'Language.TextToSpeech~~~sv-SE~0.0.1.0',
        'Language.TextToSpeech~~~ta-IN~0.0.1.0',
        'Language.TextToSpeech~~~th-TH~0.0.1.0',
        'Language.TextToSpeech~~~tr-TR~0.0.1.0',
        'Language.TextToSpeech~~~vi-VN~0.0.1.0',
        'Language.TextToSpeech~~~zh-CN~0.0.1.0',
        'Language.TextToSpeech~~~zh-HK~0.0.1.0',
        'Language.TextToSpeech~~~zh-TW~0.0.1.0',
        'MathRecognizer~~~~0.0.1.0',
        'Media.WindowsMediaPlayer~~~~0.0.12.0',
        'Microsoft.Onecore.StorageManagement~~~~0.0.1.0',
        'Microsoft.WebDriver~~~~0.0.1.0',
        'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
        'Msix.PackagingTool.Driver~~~~0.0.1.0',
        'NetFX3~~~~',
        'Network.Irda~~~~0.0.1.0',
        'OneCoreUAP.OneSync~~~~0.0.1.0',
        'OpenSSH.Client~~~~0.0.1.0',
        'OpenSSH.Server~~~~0.0.1.0',
        'RasCMAK.Client~~~~0.0.1.0',
        'RIP.Listener~~~~0.0.1.0',
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
        'Rsat.CertificateServices.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0',
        'Rsat.Dns.Tools~~~~0.0.1.0',
        'Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0',
        'Rsat.FileServices.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.IPAM.Client.Tools~~~~0.0.1.0',
        'Rsat.LLDP.Tools~~~~0.0.1.0',
        'Rsat.NetworkController.Tools~~~~0.0.1.0',
        'Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0',
        'Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0',
        'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0',
        'Rsat.ServerManager.Tools~~~~0.0.1.0',
        'Rsat.Shielded.VM.Tools~~~~0.0.1.0',
        'Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0',
        'Rsat.StorageReplica.Tools~~~~0.0.1.0',
        'Rsat.SystemInsights.Management.Tools~~~~0.0.1.0',
        'Rsat.VolumeActivation.Tools~~~~0.0.1.0',
        'Rsat.WSUS.Tools~~~~0.0.1.0',
        'SNMP.Client~~~~0.0.1.0',
        'Tools.DeveloperMode.Core~~~~0.0.1.0',
        'Tools.DTrace.Platform~~~~0.0.1.0',
        'Tools.Graphics.DirectX~~~~0.0.1.0',
        'WMI-SNMP-Provider.Client~~~~0.0.1.0',
        'XPS.Viewer~~~~0.0.1.0')
    $Win10_1903_FODs = @('Accessibility.Braille~~~~0.0.1.0',
        'Analog.Holographic.Desktop~~~~0.0.1.0',
        'App.Support.QuickAssist~~~~0.0.1.0',
        'Browser.InternetExplorer~~~~0.0.11.0',
        'Hello.Face.17658~~~~0.0.1.0',
        'Hello.Face.Migration.17658~~~~0.0.1.0',
        'Language.Basic~~~af-ZA~0.0.1.0',
        'Language.Basic~~~ar-SA~0.0.1.0',
        'Language.Basic~~~as-IN~0.0.1.0',
        'Language.Basic~~~az-LATN-AZ~0.0.1.0',
        'Language.Basic~~~ba-RU~0.0.1.0',
        'Language.Basic~~~be-BY~0.0.1.0',
        'Language.Basic~~~bg-BG~0.0.1.0',
        'Language.Basic~~~bn-BD~0.0.1.0',
        'Language.Basic~~~bn-IN~0.0.1.0',
        'Language.Basic~~~bs-LATN-BA~0.0.1.0',
        'Language.Basic~~~ca-ES~0.0.1.0',
        'Language.Basic~~~cs-CZ~0.0.1.0',
        'Language.Basic~~~cy-GB~0.0.1.0',
        'Language.Basic~~~da-DK~0.0.1.0',
        'Language.Basic~~~de-DE~0.0.1.0',
        'Language.Basic~~~el-GR~0.0.1.0',
        'Language.Basic~~~en-GB~0.0.1.0',
        'Language.Basic~~~en-US~0.0.1.0',
        'Language.Basic~~~es-ES~0.0.1.0',
        'Language.Basic~~~es-MX~0.0.1.0',
        'Language.Basic~~~et-EE~0.0.1.0',
        'Language.Basic~~~eu-ES~0.0.1.0',
        'Language.Basic~~~fa-IR~0.0.1.0',
        'Language.Basic~~~fi-FI~0.0.1.0',
        'Language.Basic~~~fil-PH~0.0.1.0',
        'Language.Basic~~~fr-CA~0.0.1.0',
        'Language.Basic~~~fr-FR~0.0.1.0',
        'Language.Basic~~~ga-IE~0.0.1.0',
        'Language.Basic~~~gd-GB~0.0.1.0',
        'Language.Basic~~~gl-ES~0.0.1.0',
        'Language.Basic~~~gu-IN~0.0.1.0',
        'Language.Basic~~~ha-LATN-NG~0.0.1.0',
        'Language.Basic~~~haw-US~0.0.1.0',
        'Language.Basic~~~he-IL~0.0.1.0',
        'Language.Basic~~~hi-IN~0.0.1.0',
        'Language.Basic~~~hr-HR~0.0.1.0',
        'Language.Basic~~~hu-HU~0.0.1.0',
        'Language.Basic~~~hy-AM~0.0.1.0',
        'Language.Basic~~~id-ID~0.0.1.0',
        'Language.Basic~~~ig-NG~0.0.1.0',
        'Language.Basic~~~is-IS~0.0.1.0',
        'Language.Basic~~~it-IT~0.0.1.0',
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Basic~~~ka-GE~0.0.1.0',
        'Language.Basic~~~kk-KZ~0.0.1.0',
        'Language.Basic~~~kl-GL~0.0.1.0',
        'Language.Basic~~~kn-IN~0.0.1.0',
        'Language.Basic~~~ko-KR~0.0.1.0',
        'Language.Basic~~~kok-DEVA-IN~0.0.1.0',
        'Language.Basic~~~ky-KG~0.0.1.0',
        'Language.Basic~~~lb-LU~0.0.1.0',
        'Language.Basic~~~lt-LT~0.0.1.0',
        'Language.Basic~~~lv-LV~0.0.1.0',
        'Language.Basic~~~mi-NZ~0.0.1.0',
        'Language.Basic~~~ml-IN~0.0.1.0',
        'Language.Basic~~~mk-MK~0.0.1.0',
        'Language.Basic~~~mn-MN~0.0.1.0',
        'Language.Basic~~~mr-IN~0.0.1.0',
        'Language.Basic~~~ms-BN~0.0.1.0',
        'Language.Basic~~~ms-MY~0.0.1.0',
        'Language.Basic~~~mt-MT~0.0.1.0',
        'Language.Basic~~~nb-NO~0.0.1.0',
        'Language.Basic~~~ne-NP~0.0.1.0',
        'Language.Basic~~~nl-NL~0.0.1.0',
        'Language.Basic~~~nn-NO~0.0.1.0',
        'Language.Basic~~~nso-ZA~0.0.1.0',
        'Language.Basic~~~or-IN~0.0.1.0',
        'Language.Basic~~~pa-IN~0.0.1.0',
        'Language.Basic~~~pl-PL~0.0.1.0',
        'Language.Basic~~~ps-AF~0.0.1.0',
        'Language.Basic~~~pt-BR~0.0.1.0',
        'Language.Basic~~~pt-PT~0.0.1.0',
        'Language.Basic~~~rm-CH~0.0.1.0',
        'Language.Basic~~~ro-RO~0.0.1.0',
        'Language.Basic~~~ru-RU~0.0.1.0',
        'Language.Basic~~~rw-RW~0.0.1.0',
        'Language.Basic~~~sah-RU~0.0.1.0',
        'Language.Basic~~~si-LK~0.0.1.0',
        'Language.Basic~~~sk-SK~0.0.1.0',
        'Language.Basic~~~sl-SI~0.0.1.0',
        'Language.Basic~~~sq-AL~0.0.1.0',
        'Language.Basic~~~sr-CYRL-RS~0.0.1.0',
        'Language.Basic~~~sr-LATN-RS~0.0.1.0',
        'Language.Basic~~~sv-SE~0.0.1.0',
        'Language.Basic~~~sw-KE~0.0.1.0',
        'Language.Basic~~~ta-IN~0.0.1.0',
        'Language.Basic~~~te-IN~0.0.1.0',
        'Language.Basic~~~tg-CYRL-TJ~0.0.1.0',
        'Language.Basic~~~th-TH~0.0.1.0',
        'Language.Basic~~~tk-TM~0.0.1.0',
        'Language.Basic~~~tn-ZA~0.0.1.0',
        'Language.Basic~~~tr-TR~0.0.1.0',
        'Language.Basic~~~tt-RU~0.0.1.0',
        'Language.Basic~~~ug-CN~0.0.1.0',
        'Language.Basic~~~uk-UA~0.0.1.0',
        'Language.Basic~~~ur-PK~0.0.1.0',
        'Language.Basic~~~uz-LATN-UZ~0.0.1.0',
        'Language.Basic~~~vi-VN~0.0.1.0',
        'Language.Basic~~~wo-SN~0.0.1.0',
        'Language.Basic~~~xh-ZA~0.0.1.0',
        'Language.Basic~~~yo-NG~0.0.1.0',
        'Language.Basic~~~zh-CN~0.0.1.0',
        'Language.Basic~~~zh-HK~0.0.1.0',
        'Language.Basic~~~zh-TW~0.0.1.0',
        'Language.Basic~~~zu-ZA~0.0.1.0',
        'Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Beng~~~und-BENG~0.0.1.0',
        'Language.Fonts.Cans~~~und-CANS~0.0.1.0',
        'Language.Fonts.Cher~~~und-CHER~0.0.1.0',
        'Language.Fonts.Deva~~~und-DEVA~0.0.1.0',
        'Language.Fonts.Ethi~~~und-ETHI~0.0.1.0',
        'Language.Fonts.Gujr~~~und-GUJR~0.0.1.0',
        'Language.Fonts.Guru~~~und-GURU~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Hebr~~~und-HEBR~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Khmr~~~und-KHMR~0.0.1.0',
        'Language.Fonts.Knda~~~und-KNDA~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Laoo~~~und-LAOO~0.0.1.0',
        'Language.Fonts.Mlym~~~und-MLYM~0.0.1.0',
        'Language.Fonts.Orya~~~und-ORYA~0.0.1.0',
        'Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0',
        'Language.Fonts.Sinh~~~und-SINH~0.0.1.0',
        'Language.Fonts.Syrc~~~und-SYRC~0.0.1.0',
        'Language.Fonts.Taml~~~und-TAML~0.0.1.0',
        'Language.Fonts.Telu~~~und-TELU~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0',
        'Language.Handwriting~~~af-ZA~0.0.1.0',
        'Language.Handwriting~~~bs-LATN-BA~0.0.1.0',
        'Language.Handwriting~~~ca-ES~0.0.1.0',
        'Language.Handwriting~~~cs-CZ~0.0.1.0',
        'Language.Handwriting~~~cy-GB~0.0.1.0',
        'Language.Handwriting~~~da-DK~0.0.1.0',
        'Language.Handwriting~~~de-DE~0.0.1.0',
        'Language.Handwriting~~~el-GR~0.0.1.0',
        'Language.Handwriting~~~en-GB~0.0.1.0',
        'Language.Handwriting~~~en-US~0.0.1.0',
        'Language.Handwriting~~~es-ES~0.0.1.0',
        'Language.Handwriting~~~es-MX~0.0.1.0',
        'Language.Handwriting~~~eu-ES~0.0.1.0',
        'Language.Handwriting~~~fi-FI~0.0.1.0',
        'Language.Handwriting~~~fr-FR~0.0.1.0',
        'Language.Handwriting~~~ga-IE~0.0.1.0',
        'Language.Handwriting~~~gd-GB~0.0.1.0',
        'Language.Handwriting~~~gl-ES~0.0.1.0',
        'Language.Handwriting~~~hi-IN~0.0.1.0',
        'Language.Handwriting~~~hr-HR~0.0.1.0',
        'Language.Handwriting~~~id-ID~0.0.1.0',
        'Language.Handwriting~~~it-IT~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.Handwriting~~~ko-KR~0.0.1.0',
        'Language.Handwriting~~~lb-LU~0.0.1.0',
        'Language.Handwriting~~~mi-NZ~0.0.1.0',
        'Language.Handwriting~~~ms-BN~0.0.1.0',
        'Language.Handwriting~~~ms-MY~0.0.1.0',
        'Language.Handwriting~~~nb-NO~0.0.1.0',
        'Language.Handwriting~~~nl-NL~0.0.1.0',
        'Language.Handwriting~~~nn-NO~0.0.1.0',
        'Language.Handwriting~~~nso-ZA~0.0.1.0',
        'Language.Handwriting~~~pl-PL~0.0.1.0',
        'Language.Handwriting~~~pt-BR~0.0.1.0',
        'Language.Handwriting~~~pt-PT~0.0.1.0',
        'Language.Handwriting~~~rm-CH~0.0.1.0',
        'Language.Handwriting~~~ro-RO~0.0.1.0',
        'Language.Handwriting~~~ru-RU~0.0.1.0',
        'Language.Handwriting~~~rw-RW~0.0.1.0',
        'Language.Handwriting~~~sk-SK~0.0.1.0',
        'Language.Handwriting~~~sl-SI~0.0.1.0',
        'Language.Handwriting~~~sq-AL~0.0.1.0',
        'Language.Handwriting~~~sr-CYRL-RS~0.0.1.0',
        'Language.Handwriting~~~sr-LATN-RS~0.0.1.0',
        'Language.Handwriting~~~sv-SE~0.0.1.0',
        'Language.Handwriting~~~sw-KE~0.0.1.0',
        'Language.Handwriting~~~tn-ZA~0.0.1.0',
        'Language.Handwriting~~~tr-TR~0.0.1.0',
        'Language.Handwriting~~~wo-SN~0.0.1.0',
        'Language.Handwriting~~~xh-ZA~0.0.1.0',
        'Language.Handwriting~~~zh-CN~0.0.1.0',
        'Language.Handwriting~~~zh-HK~0.0.1.0',
        'Language.Handwriting~~~zh-TW~0.0.1.0',
        'Language.Handwriting~~~zu-ZA~0.0.1.0',
        'Language.OCR~~~ar-SA~0.0.1.0',
        'Language.OCR~~~bg-BG~0.0.1.0',
        'Language.OCR~~~bs-LATN-BA~0.0.1.0',
        'Language.OCR~~~cs-CZ~0.0.1.0',
        'Language.OCR~~~da-DK~0.0.1.0',
        'Language.OCR~~~de-DE~0.0.1.0',
        'Language.OCR~~~el-GR~0.0.1.0',
        'Language.OCR~~~en-GB~0.0.1.0',
        'Language.OCR~~~en-US~0.0.1.0',
        'Language.OCR~~~es-ES~0.0.1.0',
        'Language.OCR~~~es-MX~0.0.1.0',
        'Language.OCR~~~fi-FI~0.0.1.0',
        'Language.OCR~~~fr-CA~0.0.1.0',
        'Language.OCR~~~fr-FR~0.0.1.0',
        'Language.OCR~~~hr-HR~0.0.1.0',
        'Language.OCR~~~hu-HU~0.0.1.0',
        'Language.OCR~~~it-IT~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ko-KR~0.0.1.0',
        'Language.OCR~~~nb-NO~0.0.1.0',
        'Language.OCR~~~nl-NL~0.0.1.0',
        'Language.OCR~~~pl-PL~0.0.1.0',
        'Language.OCR~~~pt-BR~0.0.1.0',
        'Language.OCR~~~pt-PT~0.0.1.0',
        'Language.OCR~~~ro-RO~0.0.1.0',
        'Language.OCR~~~ru-RU~0.0.1.0',
        'Language.OCR~~~sk-SK~0.0.1.0',
        'Language.OCR~~~sl-SI~0.0.1.0',
        'Language.OCR~~~sr-CYRL-RS~0.0.1.0',
        'Language.OCR~~~sr-LATN-RS~0.0.1.0',
        'Language.OCR~~~sv-SE~0.0.1.0',
        'Language.OCR~~~tr-TR~0.0.1.0',
        'Language.OCR~~~zh-CN~0.0.1.0',
        'Language.OCR~~~zh-HK~0.0.1.0',
        'Language.OCR~~~zh-TW~0.0.1.0',
        'Language.Speech~~~de-DE~0.0.1.0',
        'Language.Speech~~~en-AU~0.0.1.0',
        'Language.Speech~~~en-CA~0.0.1.0',
        'Language.Speech~~~en-GB~0.0.1.0',
        'Language.Speech~~~en-IN~0.0.1.0',
        'Language.Speech~~~en-US~0.0.1.0',
        'Language.Speech~~~es-ES~0.0.1.0',
        'Language.Speech~~~es-MX~0.0.1.0',
        'Language.Speech~~~fr-CA~0.0.1.0',
        'Language.Speech~~~fr-FR~0.0.1.0',
        'Language.Speech~~~it-IT~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.Speech~~~pt-BR~0.0.1.0',
        'Language.Speech~~~zh-CN~0.0.1.0',
        'Language.Speech~~~zh-HK~0.0.1.0',
        'Language.Speech~~~zh-TW~0.0.1.0',
        'Language.TextToSpeech~~~ar-EG~0.0.1.0',
        'Language.TextToSpeech~~~ar-SA~0.0.1.0',
        'Language.TextToSpeech~~~bg-BG~0.0.1.0',
        'Language.TextToSpeech~~~ca-ES~0.0.1.0',
        'Language.TextToSpeech~~~cs-CZ~0.0.1.0',
        'Language.TextToSpeech~~~da-DK~0.0.1.0',
        'Language.TextToSpeech~~~de-AT~0.0.1.0',
        'Language.TextToSpeech~~~de-CH~0.0.1.0',
        'Language.TextToSpeech~~~de-DE~0.0.1.0',
        'Language.TextToSpeech~~~el-GR~0.0.1.0',
        'Language.TextToSpeech~~~en-AU~0.0.1.0',
        'Language.TextToSpeech~~~en-CA~0.0.1.0',
        'Language.TextToSpeech~~~en-GB~0.0.1.0',
        'Language.TextToSpeech~~~en-IE~0.0.1.0',
        'Language.TextToSpeech~~~en-IN~0.0.1.0',
        'Language.TextToSpeech~~~en-US~0.0.1.0',
        'Language.TextToSpeech~~~es-ES~0.0.1.0',
        'Language.TextToSpeech~~~es-MX~0.0.1.0',
        'Language.TextToSpeech~~~fi-FI~0.0.1.0',
        'Language.TextToSpeech~~~fr-CA~0.0.1.0',
        'Language.TextToSpeech~~~fr-CH~0.0.1.0',
        'Language.TextToSpeech~~~fr-FR~0.0.1.0',
        'Language.TextToSpeech~~~he-IL~0.0.1.0',
        'Language.TextToSpeech~~~hi-IN~0.0.1.0',
        'Language.TextToSpeech~~~hr-HR~0.0.1.0',
        'Language.TextToSpeech~~~hu-HU~0.0.1.0',
        'Language.TextToSpeech~~~id-ID~0.0.1.0',
        'Language.TextToSpeech~~~it-IT~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ko-KR~0.0.1.0',
        'Language.TextToSpeech~~~ms-MY~0.0.1.0',
        'Language.TextToSpeech~~~nb-NO~0.0.1.0',
        'Language.TextToSpeech~~~nl-BE~0.0.1.0',
        'Language.TextToSpeech~~~nl-NL~0.0.1.0',
        'Language.TextToSpeech~~~pl-PL~0.0.1.0',
        'Language.TextToSpeech~~~pt-BR~0.0.1.0',
        'Language.TextToSpeech~~~pt-PT~0.0.1.0',
        'Language.TextToSpeech~~~ro-RO~0.0.1.0',
        'Language.TextToSpeech~~~ru-RU~0.0.1.0',
        'Language.TextToSpeech~~~sk-SK~0.0.1.0',
        'Language.TextToSpeech~~~sl-SI~0.0.1.0',
        'Language.TextToSpeech~~~sv-SE~0.0.1.0',
        'Language.TextToSpeech~~~ta-IN~0.0.1.0',
        'Language.TextToSpeech~~~th-TH~0.0.1.0',
        'Language.TextToSpeech~~~tr-TR~0.0.1.0',
        'Language.TextToSpeech~~~vi-VN~0.0.1.0',
        'Language.TextToSpeech~~~zh-CN~0.0.1.0',
        'Language.TextToSpeech~~~zh-HK~0.0.1.0',
        'Language.TextToSpeech~~~zh-TW~0.0.1.0',
        'MathRecognizer~~~~0.0.1.0',
        'Media.WindowsMediaPlayer~~~~0.0.12.0',
        'Microsoft.Onecore.StorageManagement~~~~0.0.1.0',
        'Microsoft.WebDriver~~~~0.0.1.0',
        'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
        'Msix.PackagingTool.Driver~~~~0.0.1.0',
        'NetFX3~~~~',
        'OneCoreUAP.OneSync~~~~0.0.1.0',
        'OpenSSH.Client~~~~0.0.1.0',
        'OpenSSH.Server~~~~0.0.1.0',
        'RasCMAK.Client~~~~0.0.1.0',
        'RIP.Listener~~~~0.0.1.0',
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
        'Rsat.CertificateServices.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0',
        'Rsat.Dns.Tools~~~~0.0.1.0',
        'Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0',
        'Rsat.FileServices.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.IPAM.Client.Tools~~~~0.0.1.0',
        'Rsat.LLDP.Tools~~~~0.0.1.0',
        'Rsat.NetworkController.Tools~~~~0.0.1.0',
        'Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0',
        'Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0',
        'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0',
        'Rsat.ServerManager.Tools~~~~0.0.1.0',
        'Rsat.Shielded.VM.Tools~~~~0.0.1.0',
        'Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0',
        'Rsat.StorageReplica.Tools~~~~0.0.1.0',
        'Rsat.SystemInsights.Management.Tools~~~~0.0.1.0',
        'Rsat.VolumeActivation.Tools~~~~0.0.1.0',
        'Rsat.WSUS.Tools~~~~0.0.1.0',
        'SNMP.Client~~~~0.0.1.0',
        'Tools.DeveloperMode.Core~~~~0.0.1.0',
        'Tools.DTrace.Platform~~~~0.0.1.0',
        'Tools.Graphics.DirectX~~~~0.0.1.0',
        'WMI-SNMP-Provider.Client~~~~0.0.1.0',
        'XPS.Viewer~~~~0.0.1.0')
    $Win10_1809_FODs = @('Accessibility.Braille~~~~0.0.1.0',
        'Analog.Holographic.Desktop~~~~0.0.1.0',
        'App.Support.QuickAssist~~~~0.0.1.0',
        'Browser.InternetExplorer~~~~0.0.11.0',
        'Hello.Face.17658~~~~0.0.1.0',
        'Hello.Face.Migration.17658~~~~0.0.1.0',
        'Language.Basic~~~af-ZA~0.0.1.0',
        'Language.Basic~~~ar-SA~0.0.1.0',
        'Language.Basic~~~as-IN~0.0.1.0',
        'Language.Basic~~~az-LATN-AZ~0.0.1.0',
        'Language.Basic~~~ba-RU~0.0.1.0',
        'Language.Basic~~~be-BY~0.0.1.0',
        'Language.Basic~~~bg-BG~0.0.1.0',
        'Language.Basic~~~bn-BD~0.0.1.0',
        'Language.Basic~~~bn-IN~0.0.1.0',
        'Language.Basic~~~bs-LATN-BA~0.0.1.0',
        'Language.Basic~~~ca-ES~0.0.1.0',
        'Language.Basic~~~cs-CZ~0.0.1.0',
        'Language.Basic~~~cy-GB~0.0.1.0',
        'Language.Basic~~~da-DK~0.0.1.0',
        'Language.Basic~~~de-DE~0.0.1.0',
        'Language.Basic~~~el-GR~0.0.1.0',
        'Language.Basic~~~en-GB~0.0.1.0',
        'Language.Basic~~~en-US~0.0.1.0',
        'Language.Basic~~~es-ES~0.0.1.0',
        'Language.Basic~~~es-MX~0.0.1.0',
        'Language.Basic~~~et-EE~0.0.1.0',
        'Language.Basic~~~eu-ES~0.0.1.0',
        'Language.Basic~~~fa-IR~0.0.1.0',
        'Language.Basic~~~fi-FI~0.0.1.0',
        'Language.Basic~~~fil-PH~0.0.1.0',
        'Language.Basic~~~fr-CA~0.0.1.0',
        'Language.Basic~~~fr-FR~0.0.1.0',
        'Language.Basic~~~ga-IE~0.0.1.0',
        'Language.Basic~~~gd-GB~0.0.1.0',
        'Language.Basic~~~gl-ES~0.0.1.0',
        'Language.Basic~~~gu-IN~0.0.1.0',
        'Language.Basic~~~ha-LATN-NG~0.0.1.0',
        'Language.Basic~~~haw-US~0.0.1.0',
        'Language.Basic~~~he-IL~0.0.1.0',
        'Language.Basic~~~hi-IN~0.0.1.0',
        'Language.Basic~~~hr-HR~0.0.1.0',
        'Language.Basic~~~hu-HU~0.0.1.0',
        'Language.Basic~~~hy-AM~0.0.1.0',
        'Language.Basic~~~id-ID~0.0.1.0',
        'Language.Basic~~~ig-NG~0.0.1.0',
        'Language.Basic~~~is-IS~0.0.1.0',
        'Language.Basic~~~it-IT~0.0.1.0',
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Basic~~~ka-GE~0.0.1.0',
        'Language.Basic~~~kk-KZ~0.0.1.0',
        'Language.Basic~~~kl-GL~0.0.1.0',
        'Language.Basic~~~kn-IN~0.0.1.0',
        'Language.Basic~~~ko-KR~0.0.1.0',
        'Language.Basic~~~kok-DEVA-IN~0.0.1.0',
        'Language.Basic~~~ky-KG~0.0.1.0',
        'Language.Basic~~~lb-LU~0.0.1.0',
        'Language.Basic~~~lt-LT~0.0.1.0',
        'Language.Basic~~~lv-LV~0.0.1.0',
        'Language.Basic~~~mi-NZ~0.0.1.0',
        'Language.Basic~~~ml-IN~0.0.1.0',
        'Language.Basic~~~mk-MK~0.0.1.0',
        'Language.Basic~~~mn-MN~0.0.1.0',
        'Language.Basic~~~mr-IN~0.0.1.0',
        'Language.Basic~~~ms-BN~0.0.1.0',
        'Language.Basic~~~ms-MY~0.0.1.0',
        'Language.Basic~~~mt-MT~0.0.1.0',
        'Language.Basic~~~nb-NO~0.0.1.0',
        'Language.Basic~~~ne-NP~0.0.1.0',
        'Language.Basic~~~nl-NL~0.0.1.0',
        'Language.Basic~~~nn-NO~0.0.1.0',
        'Language.Basic~~~nso-ZA~0.0.1.0',
        'Language.Basic~~~or-IN~0.0.1.0',
        'Language.Basic~~~pa-IN~0.0.1.0',
        'Language.Basic~~~pl-PL~0.0.1.0',
        'Language.Basic~~~ps-AF~0.0.1.0',
        'Language.Basic~~~pt-BR~0.0.1.0',
        'Language.Basic~~~pt-PT~0.0.1.0',
        'Language.Basic~~~rm-CH~0.0.1.0',
        'Language.Basic~~~ro-RO~0.0.1.0',
        'Language.Basic~~~ru-RU~0.0.1.0',
        'Language.Basic~~~rw-RW~0.0.1.0',
        'Language.Basic~~~sah-RU~0.0.1.0',
        'Language.Basic~~~si-LK~0.0.1.0',
        'Language.Basic~~~sk-SK~0.0.1.0',
        'Language.Basic~~~sl-SI~0.0.1.0',
        'Language.Basic~~~sq-AL~0.0.1.0',
        'Language.Basic~~~sr-CYRL-RS~0.0.1.0',
        'Language.Basic~~~sr-LATN-RS~0.0.1.0',
        'Language.Basic~~~sv-SE~0.0.1.0',
        'Language.Basic~~~sw-KE~0.0.1.0',
        'Language.Basic~~~ta-IN~0.0.1.0',
        'Language.Basic~~~te-IN~0.0.1.0',
        'Language.Basic~~~tg-CYRL-TJ~0.0.1.0',
        'Language.Basic~~~th-TH~0.0.1.0',
        'Language.Basic~~~tk-TM~0.0.1.0',
        'Language.Basic~~~tn-ZA~0.0.1.0',
        'Language.Basic~~~tr-TR~0.0.1.0',
        'Language.Basic~~~tt-RU~0.0.1.0',
        'Language.Basic~~~ug-CN~0.0.1.0',
        'Language.Basic~~~uk-UA~0.0.1.0',
        'Language.Basic~~~ur-PK~0.0.1.0',
        'Language.Basic~~~uz-LATN-UZ~0.0.1.0',
        'Language.Basic~~~vi-VN~0.0.1.0',
        'Language.Basic~~~wo-SN~0.0.1.0',
        'Language.Basic~~~xh-ZA~0.0.1.0',
        'Language.Basic~~~yo-NG~0.0.1.0',
        'Language.Basic~~~zh-CN~0.0.1.0',
        'Language.Basic~~~zh-HK~0.0.1.0',
        'Language.Basic~~~zh-TW~0.0.1.0',
        'Language.Basic~~~zu-ZA~0.0.1.0',
        'Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Beng~~~und-BENG~0.0.1.0',
        'Language.Fonts.Cans~~~und-CANS~0.0.1.0',
        'Language.Fonts.Cher~~~und-CHER~0.0.1.0',
        'Language.Fonts.Deva~~~und-DEVA~0.0.1.0',
        'Language.Fonts.Ethi~~~und-ETHI~0.0.1.0',
        'Language.Fonts.Gujr~~~und-GUJR~0.0.1.0',
        'Language.Fonts.Guru~~~und-GURU~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Hebr~~~und-HEBR~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Khmr~~~und-KHMR~0.0.1.0',
        'Language.Fonts.Knda~~~und-KNDA~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Laoo~~~und-LAOO~0.0.1.0',
        'Language.Fonts.Mlym~~~und-MLYM~0.0.1.0',
        'Language.Fonts.Orya~~~und-ORYA~0.0.1.0',
        'Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0',
        'Language.Fonts.Sinh~~~und-SINH~0.0.1.0',
        'Language.Fonts.Syrc~~~und-SYRC~0.0.1.0',
        'Language.Fonts.Taml~~~und-TAML~0.0.1.0',
        'Language.Fonts.Telu~~~und-TELU~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0',
        'Language.Handwriting~~~af-ZA~0.0.1.0',
        'Language.Handwriting~~~bs-LATN-BA~0.0.1.0',
        'Language.Handwriting~~~ca-ES~0.0.1.0',
        'Language.Handwriting~~~cs-CZ~0.0.1.0',
        'Language.Handwriting~~~cy-GB~0.0.1.0',
        'Language.Handwriting~~~da-DK~0.0.1.0',
        'Language.Handwriting~~~de-DE~0.0.1.0',
        'Language.Handwriting~~~el-GR~0.0.1.0',
        'Language.Handwriting~~~en-GB~0.0.1.0',
        'Language.Handwriting~~~en-US~0.0.1.0',
        'Language.Handwriting~~~es-ES~0.0.1.0',
        'Language.Handwriting~~~es-MX~0.0.1.0',
        'Language.Handwriting~~~eu-ES~0.0.1.0',
        'Language.Handwriting~~~fi-FI~0.0.1.0',
        'Language.Handwriting~~~fr-FR~0.0.1.0',
        'Language.Handwriting~~~ga-IE~0.0.1.0',
        'Language.Handwriting~~~gd-GB~0.0.1.0',
        'Language.Handwriting~~~gl-ES~0.0.1.0',
        'Language.Handwriting~~~hi-IN~0.0.1.0',
        'Language.Handwriting~~~hr-HR~0.0.1.0',
        'Language.Handwriting~~~id-ID~0.0.1.0',
        'Language.Handwriting~~~it-IT~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.Handwriting~~~ko-KR~0.0.1.0',
        'Language.Handwriting~~~lb-LU~0.0.1.0',
        'Language.Handwriting~~~mi-NZ~0.0.1.0',
        'Language.Handwriting~~~ms-BN~0.0.1.0',
        'Language.Handwriting~~~ms-MY~0.0.1.0',
        'Language.Handwriting~~~nb-NO~0.0.1.0',
        'Language.Handwriting~~~nl-NL~0.0.1.0',
        'Language.Handwriting~~~nn-NO~0.0.1.0',
        'Language.Handwriting~~~nso-ZA~0.0.1.0',
        'Language.Handwriting~~~pl-PL~0.0.1.0',
        'Language.Handwriting~~~pt-BR~0.0.1.0',
        'Language.Handwriting~~~pt-PT~0.0.1.0',
        'Language.Handwriting~~~rm-CH~0.0.1.0',
        'Language.Handwriting~~~ro-RO~0.0.1.0',
        'Language.Handwriting~~~ru-RU~0.0.1.0',
        'Language.Handwriting~~~rw-RW~0.0.1.0',
        'Language.Handwriting~~~sk-SK~0.0.1.0',
        'Language.Handwriting~~~sl-SI~0.0.1.0',
        'Language.Handwriting~~~sq-AL~0.0.1.0',
        'Language.Handwriting~~~sr-CYRL-RS~0.0.1.0',
        'Language.Handwriting~~~sr-LATN-RS~0.0.1.0',
        'Language.Handwriting~~~sv-SE~0.0.1.0',
        'Language.Handwriting~~~sw-KE~0.0.1.0',
        'Language.Handwriting~~~tn-ZA~0.0.1.0',
        'Language.Handwriting~~~tr-TR~0.0.1.0',
        'Language.Handwriting~~~wo-SN~0.0.1.0',
        'Language.Handwriting~~~xh-ZA~0.0.1.0',
        'Language.Handwriting~~~zh-CN~0.0.1.0',
        'Language.Handwriting~~~zh-HK~0.0.1.0',
        'Language.Handwriting~~~zh-TW~0.0.1.0',
        'Language.Handwriting~~~zu-ZA~0.0.1.0',
        'Language.OCR~~~ar-SA~0.0.1.0',
        'Language.OCR~~~bg-BG~0.0.1.0',
        'Language.OCR~~~bs-LATN-BA~0.0.1.0',
        'Language.OCR~~~cs-CZ~0.0.1.0',
        'Language.OCR~~~da-DK~0.0.1.0',
        'Language.OCR~~~de-DE~0.0.1.0',
        'Language.OCR~~~el-GR~0.0.1.0',
        'Language.OCR~~~en-GB~0.0.1.0',
        'Language.OCR~~~en-US~0.0.1.0',
        'Language.OCR~~~es-ES~0.0.1.0',
        'Language.OCR~~~es-MX~0.0.1.0',
        'Language.OCR~~~fi-FI~0.0.1.0',
        'Language.OCR~~~fr-CA~0.0.1.0',
        'Language.OCR~~~fr-FR~0.0.1.0',
        'Language.OCR~~~hr-HR~0.0.1.0',
        'Language.OCR~~~hu-HU~0.0.1.0',
        'Language.OCR~~~it-IT~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ko-KR~0.0.1.0',
        'Language.OCR~~~nb-NO~0.0.1.0',
        'Language.OCR~~~nl-NL~0.0.1.0',
        'Language.OCR~~~pl-PL~0.0.1.0',
        'Language.OCR~~~pt-BR~0.0.1.0',
        'Language.OCR~~~pt-PT~0.0.1.0',
        'Language.OCR~~~ro-RO~0.0.1.0',
        'Language.OCR~~~ru-RU~0.0.1.0',
        'Language.OCR~~~sk-SK~0.0.1.0',
        'Language.OCR~~~sl-SI~0.0.1.0',
        'Language.OCR~~~sr-CYRL-RS~0.0.1.0',
        'Language.OCR~~~sr-LATN-RS~0.0.1.0',
        'Language.OCR~~~sv-SE~0.0.1.0',
        'Language.OCR~~~tr-TR~0.0.1.0',
        'Language.OCR~~~zh-CN~0.0.1.0',
        'Language.OCR~~~zh-HK~0.0.1.0',
        'Language.OCR~~~zh-TW~0.0.1.0',
        'Language.Speech~~~de-DE~0.0.1.0',
        'Language.Speech~~~en-AU~0.0.1.0',
        'Language.Speech~~~en-CA~0.0.1.0',
        'Language.Speech~~~en-GB~0.0.1.0',
        'Language.Speech~~~en-IN~0.0.1.0',
        'Language.Speech~~~en-US~0.0.1.0',
        'Language.Speech~~~es-ES~0.0.1.0',
        'Language.Speech~~~es-MX~0.0.1.0',
        'Language.Speech~~~fr-CA~0.0.1.0',
        'Language.Speech~~~fr-FR~0.0.1.0',
        'Language.Speech~~~it-IT~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.Speech~~~pt-BR~0.0.1.0',
        'Language.Speech~~~zh-CN~0.0.1.0',
        'Language.Speech~~~zh-HK~0.0.1.0',
        'Language.Speech~~~zh-TW~0.0.1.0',
        'Language.TextToSpeech~~~ar-EG~0.0.1.0',
        'Language.TextToSpeech~~~ar-SA~0.0.1.0',
        'Language.TextToSpeech~~~bg-BG~0.0.1.0',
        'Language.TextToSpeech~~~ca-ES~0.0.1.0',
        'Language.TextToSpeech~~~cs-CZ~0.0.1.0',
        'Language.TextToSpeech~~~da-DK~0.0.1.0',
        'Language.TextToSpeech~~~de-AT~0.0.1.0',
        'Language.TextToSpeech~~~de-CH~0.0.1.0',
        'Language.TextToSpeech~~~de-DE~0.0.1.0',
        'Language.TextToSpeech~~~el-GR~0.0.1.0',
        'Language.TextToSpeech~~~en-AU~0.0.1.0',
        'Language.TextToSpeech~~~en-CA~0.0.1.0',
        'Language.TextToSpeech~~~en-GB~0.0.1.0',
        'Language.TextToSpeech~~~en-IE~0.0.1.0',
        'Language.TextToSpeech~~~en-IN~0.0.1.0',
        'Language.TextToSpeech~~~en-US~0.0.1.0',
        'Language.TextToSpeech~~~es-ES~0.0.1.0',
        'Language.TextToSpeech~~~es-MX~0.0.1.0',
        'Language.TextToSpeech~~~fi-FI~0.0.1.0',
        'Language.TextToSpeech~~~fr-CA~0.0.1.0',
        'Language.TextToSpeech~~~fr-CH~0.0.1.0',
        'Language.TextToSpeech~~~fr-FR~0.0.1.0',
        'Language.TextToSpeech~~~he-IL~0.0.1.0',
        'Language.TextToSpeech~~~hi-IN~0.0.1.0',
        'Language.TextToSpeech~~~hr-HR~0.0.1.0',
        'Language.TextToSpeech~~~hu-HU~0.0.1.0',
        'Language.TextToSpeech~~~id-ID~0.0.1.0',
        'Language.TextToSpeech~~~it-IT~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ko-KR~0.0.1.0',
        'Language.TextToSpeech~~~ms-MY~0.0.1.0',
        'Language.TextToSpeech~~~nb-NO~0.0.1.0',
        'Language.TextToSpeech~~~nl-BE~0.0.1.0',
        'Language.TextToSpeech~~~nl-NL~0.0.1.0',
        'Language.TextToSpeech~~~pl-PL~0.0.1.0',
        'Language.TextToSpeech~~~pt-BR~0.0.1.0',
        'Language.TextToSpeech~~~pt-PT~0.0.1.0',
        'Language.TextToSpeech~~~ro-RO~0.0.1.0',
        'Language.TextToSpeech~~~ru-RU~0.0.1.0',
        'Language.TextToSpeech~~~sk-SK~0.0.1.0',
        'Language.TextToSpeech~~~sl-SI~0.0.1.0',
        'Language.TextToSpeech~~~sv-SE~0.0.1.0',
        'Language.TextToSpeech~~~ta-IN~0.0.1.0',
        'Language.TextToSpeech~~~th-TH~0.0.1.0',
        'Language.TextToSpeech~~~tr-TR~0.0.1.0',
        'Language.TextToSpeech~~~vi-VN~0.0.1.0',
        'Language.TextToSpeech~~~zh-CN~0.0.1.0',
        'Language.TextToSpeech~~~zh-HK~0.0.1.0',
        'Language.TextToSpeech~~~zh-TW~0.0.1.0',
        'MathRecognizer~~~~0.0.1.0',
        'Media.WindowsMediaPlayer~~~~0.0.12.0',
        'Microsoft.Onecore.StorageManagement~~~~0.0.1.0',
        'Microsoft.WebDriver~~~~0.0.1.0',
        'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
        'Msix.PackagingTool.Driver~~~~0.0.1.0',
        'NetFX3~~~~'
        'OneCoreUAP.OneSync~~~~0.0.1.0',
        'OpenSSH.Client~~~~0.0.1.0',
        'OpenSSH.Server~~~~0.0.1.0',
        'RasCMAK.Client~~~~0.0.1.0',
        'RIP.Listener~~~~0.0.1.0',
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
        'Rsat.CertificateServices.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0',
        'Rsat.Dns.Tools~~~~0.0.1.0',
        'Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0',
        'Rsat.FileServices.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.IPAM.Client.Tools~~~~0.0.1.0',
        'Rsat.LLDP.Tools~~~~0.0.1.0',
        'Rsat.NetworkController.Tools~~~~0.0.1.0',
        'Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0',
        'Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0',
        'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0',
        'Rsat.ServerManager.Tools~~~~0.0.1.0',
        'Rsat.Shielded.VM.Tools~~~~0.0.1.0',
        'Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0',
        'Rsat.StorageReplica.Tools~~~~0.0.1.0',
        'Rsat.SystemInsights.Management.Tools~~~~0.0.1.0',
        'Rsat.VolumeActivation.Tools~~~~0.0.1.0',
        'Rsat.WSUS.Tools~~~~0.0.1.0',
        'SNMP.Client~~~~0.0.1.0',
        'Tools.DeveloperMode.Core~~~~0.0.1.0',
        'Tools.DTrace.Platform~~~~0.0.1.0',
        'Tools.Graphics.DirectX~~~~0.0.1.0',
        'WMI-SNMP-Provider.Client~~~~0.0.1.0',
        'XPS.Viewer~~~~0.0.1.0'
    )
    $Win10_1809_server_FODs = @('Accessibility.Braille~~~~0.0.1.0',
        'Analog.Holographic.Desktop~~~~0.0.1.0',
        'App.Support.QuickAssist~~~~0.0.1.0',
        'Browser.InternetExplorer~~~~0.0.11.0',
        'Hello.Face.17658~~~~0.0.1.0',
        'Hello.Face.Migration.17658~~~~0.0.1.0',
        'Language.Basic~~~af-ZA~0.0.1.0',
        'Language.Basic~~~ar-SA~0.0.1.0',
        'Language.Basic~~~as-IN~0.0.1.0',
        'Language.Basic~~~az-LATN-AZ~0.0.1.0',
        'Language.Basic~~~ba-RU~0.0.1.0',
        'Language.Basic~~~be-BY~0.0.1.0',
        'Language.Basic~~~bg-BG~0.0.1.0',
        'Language.Basic~~~bn-BD~0.0.1.0',
        'Language.Basic~~~bn-IN~0.0.1.0',
        'Language.Basic~~~bs-LATN-BA~0.0.1.0',
        'Language.Basic~~~ca-ES~0.0.1.0',
        'Language.Basic~~~cs-CZ~0.0.1.0',
        'Language.Basic~~~cy-GB~0.0.1.0',
        'Language.Basic~~~da-DK~0.0.1.0',
        'Language.Basic~~~de-DE~0.0.1.0',
        'Language.Basic~~~el-GR~0.0.1.0',
        'Language.Basic~~~en-GB~0.0.1.0',
        'Language.Basic~~~en-US~0.0.1.0',
        'Language.Basic~~~es-ES~0.0.1.0',
        'Language.Basic~~~es-MX~0.0.1.0',
        'Language.Basic~~~et-EE~0.0.1.0',
        'Language.Basic~~~eu-ES~0.0.1.0',
        'Language.Basic~~~fa-IR~0.0.1.0',
        'Language.Basic~~~fi-FI~0.0.1.0',
        'Language.Basic~~~fil-PH~0.0.1.0',
        'Language.Basic~~~fr-CA~0.0.1.0',
        'Language.Basic~~~fr-FR~0.0.1.0',
        'Language.Basic~~~ga-IE~0.0.1.0',
        'Language.Basic~~~gd-GB~0.0.1.0',
        'Language.Basic~~~gl-ES~0.0.1.0',
        'Language.Basic~~~gu-IN~0.0.1.0',
        'Language.Basic~~~ha-LATN-NG~0.0.1.0',
        'Language.Basic~~~haw-US~0.0.1.0',
        'Language.Basic~~~he-IL~0.0.1.0',
        'Language.Basic~~~hi-IN~0.0.1.0',
        'Language.Basic~~~hr-HR~0.0.1.0',
        'Language.Basic~~~hu-HU~0.0.1.0',
        'Language.Basic~~~hy-AM~0.0.1.0',
        'Language.Basic~~~id-ID~0.0.1.0',
        'Language.Basic~~~ig-NG~0.0.1.0',
        'Language.Basic~~~is-IS~0.0.1.0',
        'Language.Basic~~~it-IT~0.0.1.0',
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Basic~~~ka-GE~0.0.1.0',
        'Language.Basic~~~kk-KZ~0.0.1.0',
        'Language.Basic~~~kl-GL~0.0.1.0',
        'Language.Basic~~~kn-IN~0.0.1.0',
        'Language.Basic~~~ko-KR~0.0.1.0',
        'Language.Basic~~~kok-DEVA-IN~0.0.1.0',
        'Language.Basic~~~ky-KG~0.0.1.0',
        'Language.Basic~~~lb-LU~0.0.1.0',
        'Language.Basic~~~lt-LT~0.0.1.0',
        'Language.Basic~~~lv-LV~0.0.1.0',
        'Language.Basic~~~mi-NZ~0.0.1.0',
        'Language.Basic~~~ml-IN~0.0.1.0',
        'Language.Basic~~~mk-MK~0.0.1.0',
        'Language.Basic~~~mn-MN~0.0.1.0',
        'Language.Basic~~~mr-IN~0.0.1.0',
        'Language.Basic~~~ms-BN~0.0.1.0',
        'Language.Basic~~~ms-MY~0.0.1.0',
        'Language.Basic~~~mt-MT~0.0.1.0',
        'Language.Basic~~~nb-NO~0.0.1.0',
        'Language.Basic~~~ne-NP~0.0.1.0',
        'Language.Basic~~~nl-NL~0.0.1.0',
        'Language.Basic~~~nn-NO~0.0.1.0',
        'Language.Basic~~~nso-ZA~0.0.1.0',
        'Language.Basic~~~or-IN~0.0.1.0',
        'Language.Basic~~~pa-IN~0.0.1.0',
        'Language.Basic~~~pl-PL~0.0.1.0',
        'Language.Basic~~~ps-AF~0.0.1.0',
        'Language.Basic~~~pt-BR~0.0.1.0',
        'Language.Basic~~~pt-PT~0.0.1.0',
        'Language.Basic~~~rm-CH~0.0.1.0',
        'Language.Basic~~~ro-RO~0.0.1.0',
        'Language.Basic~~~ru-RU~0.0.1.0',
        'Language.Basic~~~rw-RW~0.0.1.0',
        'Language.Basic~~~sah-RU~0.0.1.0',
        'Language.Basic~~~si-LK~0.0.1.0',
        'Language.Basic~~~sk-SK~0.0.1.0',
        'Language.Basic~~~sl-SI~0.0.1.0',
        'Language.Basic~~~sq-AL~0.0.1.0',
        'Language.Basic~~~sr-CYRL-RS~0.0.1.0',
        'Language.Basic~~~sr-LATN-RS~0.0.1.0',
        'Language.Basic~~~sv-SE~0.0.1.0',
        'Language.Basic~~~sw-KE~0.0.1.0',
        'Language.Basic~~~ta-IN~0.0.1.0',
        'Language.Basic~~~te-IN~0.0.1.0',
        'Language.Basic~~~tg-CYRL-TJ~0.0.1.0',
        'Language.Basic~~~th-TH~0.0.1.0',
        'Language.Basic~~~tk-TM~0.0.1.0',
        'Language.Basic~~~tn-ZA~0.0.1.0',
        'Language.Basic~~~tr-TR~0.0.1.0',
        'Language.Basic~~~tt-RU~0.0.1.0',
        'Language.Basic~~~ug-CN~0.0.1.0',
        'Language.Basic~~~uk-UA~0.0.1.0',
        'Language.Basic~~~ur-PK~0.0.1.0',
        'Language.Basic~~~uz-LATN-UZ~0.0.1.0',
        'Language.Basic~~~vi-VN~0.0.1.0',
        'Language.Basic~~~wo-SN~0.0.1.0',
        'Language.Basic~~~xh-ZA~0.0.1.0',
        'Language.Basic~~~yo-NG~0.0.1.0',
        'Language.Basic~~~zh-CN~0.0.1.0',
        'Language.Basic~~~zh-HK~0.0.1.0',
        'Language.Basic~~~zh-TW~0.0.1.0',
        'Language.Basic~~~zu-ZA~0.0.1.0',
        'Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Beng~~~und-BENG~0.0.1.0',
        'Language.Fonts.Cans~~~und-CANS~0.0.1.0',
        'Language.Fonts.Cher~~~und-CHER~0.0.1.0',
        'Language.Fonts.Deva~~~und-DEVA~0.0.1.0',
        'Language.Fonts.Ethi~~~und-ETHI~0.0.1.0',
        'Language.Fonts.Gujr~~~und-GUJR~0.0.1.0',
        'Language.Fonts.Guru~~~und-GURU~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Hebr~~~und-HEBR~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Khmr~~~und-KHMR~0.0.1.0',
        'Language.Fonts.Knda~~~und-KNDA~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Laoo~~~und-LAOO~0.0.1.0',
        'Language.Fonts.Mlym~~~und-MLYM~0.0.1.0',
        'Language.Fonts.Orya~~~und-ORYA~0.0.1.0',
        'Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0',
        'Language.Fonts.Sinh~~~und-SINH~0.0.1.0',
        'Language.Fonts.Syrc~~~und-SYRC~0.0.1.0',
        'Language.Fonts.Taml~~~und-TAML~0.0.1.0',
        'Language.Fonts.Telu~~~und-TELU~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0',
        'Language.Handwriting~~~af-ZA~0.0.1.0',
        'Language.Handwriting~~~bs-LATN-BA~0.0.1.0',
        'Language.Handwriting~~~ca-ES~0.0.1.0',
        'Language.Handwriting~~~cs-CZ~0.0.1.0',
        'Language.Handwriting~~~cy-GB~0.0.1.0',
        'Language.Handwriting~~~da-DK~0.0.1.0',
        'Language.Handwriting~~~de-DE~0.0.1.0',
        'Language.Handwriting~~~el-GR~0.0.1.0',
        'Language.Handwriting~~~en-GB~0.0.1.0',
        'Language.Handwriting~~~en-US~0.0.1.0',
        'Language.Handwriting~~~es-ES~0.0.1.0',
        'Language.Handwriting~~~es-MX~0.0.1.0',
        'Language.Handwriting~~~eu-ES~0.0.1.0',
        'Language.Handwriting~~~fi-FI~0.0.1.0',
        'Language.Handwriting~~~fr-FR~0.0.1.0',
        'Language.Handwriting~~~ga-IE~0.0.1.0',
        'Language.Handwriting~~~gd-GB~0.0.1.0',
        'Language.Handwriting~~~gl-ES~0.0.1.0',
        'Language.Handwriting~~~hi-IN~0.0.1.0',
        'Language.Handwriting~~~hr-HR~0.0.1.0',
        'Language.Handwriting~~~id-ID~0.0.1.0',
        'Language.Handwriting~~~it-IT~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.Handwriting~~~ko-KR~0.0.1.0',
        'Language.Handwriting~~~lb-LU~0.0.1.0',
        'Language.Handwriting~~~mi-NZ~0.0.1.0',
        'Language.Handwriting~~~ms-BN~0.0.1.0',
        'Language.Handwriting~~~ms-MY~0.0.1.0',
        'Language.Handwriting~~~nb-NO~0.0.1.0',
        'Language.Handwriting~~~nl-NL~0.0.1.0',
        'Language.Handwriting~~~nn-NO~0.0.1.0',
        'Language.Handwriting~~~nso-ZA~0.0.1.0',
        'Language.Handwriting~~~pl-PL~0.0.1.0',
        'Language.Handwriting~~~pt-BR~0.0.1.0',
        'Language.Handwriting~~~pt-PT~0.0.1.0',
        'Language.Handwriting~~~rm-CH~0.0.1.0',
        'Language.Handwriting~~~ro-RO~0.0.1.0',
        'Language.Handwriting~~~ru-RU~0.0.1.0',
        'Language.Handwriting~~~rw-RW~0.0.1.0',
        'Language.Handwriting~~~sk-SK~0.0.1.0',
        'Language.Handwriting~~~sl-SI~0.0.1.0',
        'Language.Handwriting~~~sq-AL~0.0.1.0',
        'Language.Handwriting~~~sr-CYRL-RS~0.0.1.0',
        'Language.Handwriting~~~sr-LATN-RS~0.0.1.0',
        'Language.Handwriting~~~sv-SE~0.0.1.0',
        'Language.Handwriting~~~sw-KE~0.0.1.0',
        'Language.Handwriting~~~tn-ZA~0.0.1.0',
        'Language.Handwriting~~~tr-TR~0.0.1.0',
        'Language.Handwriting~~~wo-SN~0.0.1.0',
        'Language.Handwriting~~~xh-ZA~0.0.1.0',
        'Language.Handwriting~~~zh-CN~0.0.1.0',
        'Language.Handwriting~~~zh-HK~0.0.1.0',
        'Language.Handwriting~~~zh-TW~0.0.1.0',
        'Language.Handwriting~~~zu-ZA~0.0.1.0',
        'Language.OCR~~~ar-SA~0.0.1.0',
        'Language.OCR~~~bg-BG~0.0.1.0',
        'Language.OCR~~~bs-LATN-BA~0.0.1.0',
        'Language.OCR~~~cs-CZ~0.0.1.0',
        'Language.OCR~~~da-DK~0.0.1.0',
        'Language.OCR~~~de-DE~0.0.1.0',
        'Language.OCR~~~el-GR~0.0.1.0',
        'Language.OCR~~~en-GB~0.0.1.0',
        'Language.OCR~~~en-US~0.0.1.0',
        'Language.OCR~~~es-ES~0.0.1.0',
        'Language.OCR~~~es-MX~0.0.1.0',
        'Language.OCR~~~fi-FI~0.0.1.0',
        'Language.OCR~~~fr-CA~0.0.1.0',
        'Language.OCR~~~fr-FR~0.0.1.0',
        'Language.OCR~~~hr-HR~0.0.1.0',
        'Language.OCR~~~hu-HU~0.0.1.0',
        'Language.OCR~~~it-IT~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ko-KR~0.0.1.0',
        'Language.OCR~~~nb-NO~0.0.1.0',
        'Language.OCR~~~nl-NL~0.0.1.0',
        'Language.OCR~~~pl-PL~0.0.1.0',
        'Language.OCR~~~pt-BR~0.0.1.0',
        'Language.OCR~~~pt-PT~0.0.1.0',
        'Language.OCR~~~ro-RO~0.0.1.0',
        'Language.OCR~~~ru-RU~0.0.1.0',
        'Language.OCR~~~sk-SK~0.0.1.0',
        'Language.OCR~~~sl-SI~0.0.1.0',
        'Language.OCR~~~sr-CYRL-RS~0.0.1.0',
        'Language.OCR~~~sr-LATN-RS~0.0.1.0',
        'Language.OCR~~~sv-SE~0.0.1.0',
        'Language.OCR~~~tr-TR~0.0.1.0',
        'Language.OCR~~~zh-CN~0.0.1.0',
        'Language.OCR~~~zh-HK~0.0.1.0',
        'Language.OCR~~~zh-TW~0.0.1.0',
        'Language.Speech~~~de-DE~0.0.1.0',
        'Language.Speech~~~en-AU~0.0.1.0',
        'Language.Speech~~~en-CA~0.0.1.0',
        'Language.Speech~~~en-GB~0.0.1.0',
        'Language.Speech~~~en-IN~0.0.1.0',
        'Language.Speech~~~en-US~0.0.1.0',
        'Language.Speech~~~es-ES~0.0.1.0',
        'Language.Speech~~~es-MX~0.0.1.0',
        'Language.Speech~~~fr-CA~0.0.1.0',
        'Language.Speech~~~fr-FR~0.0.1.0',
        'Language.Speech~~~it-IT~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.Speech~~~pt-BR~0.0.1.0',
        'Language.Speech~~~zh-CN~0.0.1.0',
        'Language.Speech~~~zh-HK~0.0.1.0',
        'Language.Speech~~~zh-TW~0.0.1.0',
        'Language.TextToSpeech~~~ar-EG~0.0.1.0',
        'Language.TextToSpeech~~~ar-SA~0.0.1.0',
        'Language.TextToSpeech~~~bg-BG~0.0.1.0',
        'Language.TextToSpeech~~~ca-ES~0.0.1.0',
        'Language.TextToSpeech~~~cs-CZ~0.0.1.0',
        'Language.TextToSpeech~~~da-DK~0.0.1.0',
        'Language.TextToSpeech~~~de-AT~0.0.1.0',
        'Language.TextToSpeech~~~de-CH~0.0.1.0',
        'Language.TextToSpeech~~~de-DE~0.0.1.0',
        'Language.TextToSpeech~~~el-GR~0.0.1.0',
        'Language.TextToSpeech~~~en-AU~0.0.1.0',
        'Language.TextToSpeech~~~en-CA~0.0.1.0',
        'Language.TextToSpeech~~~en-GB~0.0.1.0',
        'Language.TextToSpeech~~~en-IE~0.0.1.0',
        'Language.TextToSpeech~~~en-IN~0.0.1.0',
        'Language.TextToSpeech~~~en-US~0.0.1.0',
        'Language.TextToSpeech~~~es-ES~0.0.1.0',
        'Language.TextToSpeech~~~es-MX~0.0.1.0',
        'Language.TextToSpeech~~~fi-FI~0.0.1.0',
        'Language.TextToSpeech~~~fr-CA~0.0.1.0',
        'Language.TextToSpeech~~~fr-CH~0.0.1.0',
        'Language.TextToSpeech~~~fr-FR~0.0.1.0',
        'Language.TextToSpeech~~~he-IL~0.0.1.0',
        'Language.TextToSpeech~~~hi-IN~0.0.1.0',
        'Language.TextToSpeech~~~hr-HR~0.0.1.0',
        'Language.TextToSpeech~~~hu-HU~0.0.1.0',
        'Language.TextToSpeech~~~id-ID~0.0.1.0',
        'Language.TextToSpeech~~~it-IT~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ko-KR~0.0.1.0',
        'Language.TextToSpeech~~~ms-MY~0.0.1.0',
        'Language.TextToSpeech~~~nb-NO~0.0.1.0',
        'Language.TextToSpeech~~~nl-BE~0.0.1.0',
        'Language.TextToSpeech~~~nl-NL~0.0.1.0',
        'Language.TextToSpeech~~~pl-PL~0.0.1.0',
        'Language.TextToSpeech~~~pt-BR~0.0.1.0',
        'Language.TextToSpeech~~~pt-PT~0.0.1.0',
        'Language.TextToSpeech~~~ro-RO~0.0.1.0',
        'Language.TextToSpeech~~~ru-RU~0.0.1.0',
        'Language.TextToSpeech~~~sk-SK~0.0.1.0',
        'Language.TextToSpeech~~~sl-SI~0.0.1.0',
        'Language.TextToSpeech~~~sv-SE~0.0.1.0',
        'Language.TextToSpeech~~~ta-IN~0.0.1.0',
        'Language.TextToSpeech~~~th-TH~0.0.1.0',
        'Language.TextToSpeech~~~tr-TR~0.0.1.0',
        'Language.TextToSpeech~~~vi-VN~0.0.1.0',
        'Language.TextToSpeech~~~zh-CN~0.0.1.0',
        'Language.TextToSpeech~~~zh-HK~0.0.1.0',
        'Language.TextToSpeech~~~zh-TW~0.0.1.0',
        'MathRecognizer~~~~0.0.1.0',
        'Media.WindowsMediaPlayer~~~~0.0.12.0',
        'Microsoft.Onecore.StorageManagement~~~~0.0.1.0',
        'Microsoft.WebDriver~~~~0.0.1.0',
        'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
        'Msix.PackagingTool.Driver~~~~0.0.1.0',
        'NetFX3~~~~'
        'OneCoreUAP.OneSync~~~~0.0.1.0',
        'OpenSSH.Client~~~~0.0.1.0',
        'OpenSSH.Server~~~~0.0.1.0',
        'RasCMAK.Client~~~~0.0.1.0',
        'RIP.Listener~~~~0.0.1.0',
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
        'Rsat.CertificateServices.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0',
        'Rsat.Dns.Tools~~~~0.0.1.0',
        'Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0',
        'Rsat.FileServices.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.IPAM.Client.Tools~~~~0.0.1.0',
        'Rsat.LLDP.Tools~~~~0.0.1.0',
        'Rsat.NetworkController.Tools~~~~0.0.1.0',
        'Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0',
        'Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0',
        'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0',
        'Rsat.ServerManager.Tools~~~~0.0.1.0',
        'Rsat.Shielded.VM.Tools~~~~0.0.1.0',
        'Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0',
        'Rsat.StorageReplica.Tools~~~~0.0.1.0',
        'Rsat.SystemInsights.Management.Tools~~~~0.0.1.0',
        'Rsat.VolumeActivation.Tools~~~~0.0.1.0',
        'Rsat.WSUS.Tools~~~~0.0.1.0',
        'ServerCore.AppCompatibility~~~~0.0.1.0',
        'SNMP.Client~~~~0.0.1.0',
        'Tools.DeveloperMode.Core~~~~0.0.1.0',
        'Tools.DTrace.Platform~~~~0.0.1.0',
        'Tools.Graphics.DirectX~~~~0.0.1.0',
        'WMI-SNMP-Provider.Client~~~~0.0.1.0',
        'XPS.Viewer~~~~0.0.1.0'
    )
    $Win10_2004_FODs = @('Accessibility.Braille~~~~0.0.1.0',
        'Analog.Holographic.Desktop~~~~0.0.1.0',
        'App.StepsRecorder~~~~0.0.1.0',
        'App.Support.QuickAssist~~~~0.0.1.0',
        'App.WirelessDisplay.Connect~~~~0.0.1.0',
        'Browser.InternetExplorer~~~~0.0.11.0',
        'DirectX.Configuration.Database~~~~0.0.1.0',
        'Hello.Face.18967~~~~0.0.1.0',
        'Hello.Face.Migration.18967~~~~0.0.1.0',
        'Language.Basic~~~af-ZA~0.0.1.0',
        'Language.Basic~~~ar-SA~0.0.1.0',
        'Language.Basic~~~as-IN~0.0.1.0',
        'Language.Basic~~~az-LATN-AZ~0.0.1.0',
        'Language.Basic~~~ba-RU~0.0.1.0',
        'Language.Basic~~~be-BY~0.0.1.0',
        'Language.Basic~~~bg-BG~0.0.1.0',
        'Language.Basic~~~bn-BD~0.0.1.0',
        'Language.Basic~~~bn-IN~0.0.1.0',
        'Language.Basic~~~bs-LATN-BA~0.0.1.0',
        'Language.Basic~~~ca-ES~0.0.1.0',
        'Language.Basic~~~cs-CZ~0.0.1.0',
        'Language.Basic~~~cy-GB~0.0.1.0',
        'Language.Basic~~~da-DK~0.0.1.0',
        'Language.Basic~~~de-CH~0.0.1.0',
        'Language.Basic~~~de-DE~0.0.1.0',
        'Language.Basic~~~el-GR~0.0.1.0',
        'Language.Basic~~~en-AU~0.0.1.0',
        'Language.Basic~~~en-CA~0.0.1.0',
        'Language.Basic~~~en-GB~0.0.1.0',
        'Language.Basic~~~en-IN~0.0.1.0',
        'Language.Basic~~~en-US~0.0.1.0',
        'Language.Basic~~~es-ES~0.0.1.0',
        'Language.Basic~~~es-MX~0.0.1.0',
        'Language.Basic~~~es-US~0.0.1.0',
        'Language.Basic~~~et-EE~0.0.1.0',
        'Language.Basic~~~eu-ES~0.0.1.0',
        'Language.Basic~~~fa-IR~0.0.1.0',
        'Language.Basic~~~fi-FI~0.0.1.0',
        'Language.Basic~~~fil-PH~0.0.1.0',
        'Language.Basic~~~fr-BE~0.0.1.0',
        'Language.Basic~~~fr-CA~0.0.1.0',
        'Language.Basic~~~fr-CH~0.0.1.0',
        'Language.Basic~~~fr-FR~0.0.1.0',
        'Language.Basic~~~ga-IE~0.0.1.0',
        'Language.Basic~~~gd-GB~0.0.1.0',
        'Language.Basic~~~gl-ES~0.0.1.0',
        'Language.Basic~~~gu-IN~0.0.1.0',
        'Language.Basic~~~ha-LATN-NG~0.0.1.0',
        'Language.Basic~~~haw-US~0.0.1.0',
        'Language.Basic~~~he-IL~0.0.1.0',
        'Language.Basic~~~hi-IN~0.0.1.0',
        'Language.Basic~~~hr-HR~0.0.1.0',
        'Language.Basic~~~hu-HU~0.0.1.0',
        'Language.Basic~~~hy-AM~0.0.1.0',
        'Language.Basic~~~id-ID~0.0.1.0',
        'Language.Basic~~~ig-NG~0.0.1.0',
        'Language.Basic~~~is-IS~0.0.1.0',
        'Language.Basic~~~it-IT~0.0.1.0',
        'Language.Basic~~~ja-JP~0.0.1.0',
        'Language.Basic~~~ka-GE~0.0.1.0',
        'Language.Basic~~~kk-KZ~0.0.1.0',
        'Language.Basic~~~kl-GL~0.0.1.0',
        'Language.Basic~~~kn-IN~0.0.1.0',
        'Language.Basic~~~ko-KR~0.0.1.0',
        'Language.Basic~~~kok-DEVA-IN~0.0.1.0',
        'Language.Basic~~~ky-KG~0.0.1.0',
        'Language.Basic~~~lb-LU~0.0.1.0',
        'Language.Basic~~~lt-LT~0.0.1.0',
        'Language.Basic~~~lv-LV~0.0.1.0',
        'Language.Basic~~~mi-NZ~0.0.1.0',
        'Language.Basic~~~mk-MK~0.0.1.0',
        'Language.Basic~~~ml-IN~0.0.1.0',
        'Language.Basic~~~mn-MN~0.0.1.0',
        'Language.Basic~~~mr-IN~0.0.1.0',
        'Language.Basic~~~ms-BN~0.0.1.0',
        'Language.Basic~~~ms-MY~0.0.1.0',
        'Language.Basic~~~mt-MT~0.0.1.0',
        'Language.Basic~~~nb-NO~0.0.1.0',
        'Language.Basic~~~ne-NP~0.0.1.0',
        'Language.Basic~~~nl-NL~0.0.1.0',
        'Language.Basic~~~nn-NO~0.0.1.0',
        'Language.Basic~~~nso-ZA~0.0.1.0',
        'Language.Basic~~~or-IN~0.0.1.0',
        'Language.Basic~~~pa-IN~0.0.1.0',
        'Language.Basic~~~pl-PL~0.0.1.0',
        'Language.Basic~~~ps-AF~0.0.1.0',
        'Language.Basic~~~pt-BR~0.0.1.0',
        'Language.Basic~~~pt-PT~0.0.1.0',
        'Language.Basic~~~rm-CH~0.0.1.0',
        'Language.Basic~~~ro-RO~0.0.1.0',
        'Language.Basic~~~ru-RU~0.0.1.0',
        'Language.Basic~~~rw-RW~0.0.1.0',
        'Language.Basic~~~sah-RU~0.0.1.0',
        'Language.Basic~~~si-LK~0.0.1.0',
        'Language.Basic~~~sk-SK~0.0.1.0',
        'Language.Basic~~~sl-SI~0.0.1.0',
        'Language.Basic~~~sq-AL~0.0.1.0',
        'Language.Basic~~~sr-CYRL-RS~0.0.1.0',
        'Language.Basic~~~sr-LATN-RS~0.0.1.0',
        'Language.Basic~~~sv-SE~0.0.1.0',
        'Language.Basic~~~sw-KE~0.0.1.0',
        'Language.Basic~~~ta-IN~0.0.1.0',
        'Language.Basic~~~te-IN~0.0.1.0',
        'Language.Basic~~~tg-CYRL-TJ~0.0.1.0',
        'Language.Basic~~~th-TH~0.0.1.0',
        'Language.Basic~~~tk-TM~0.0.1.0',
        'Language.Basic~~~tn-ZA~0.0.1.0',
        'Language.Basic~~~tr-TR~0.0.1.0',
        'Language.Basic~~~tt-RU~0.0.1.0',
        'Language.Basic~~~ug-CN~0.0.1.0',
        'Language.Basic~~~uk-UA~0.0.1.0',
        'Language.Basic~~~ur-PK~0.0.1.0',
        'Language.Basic~~~uz-LATN-UZ~0.0.1.0',
        'Language.Basic~~~vi-VN~0.0.1.0',
        'Language.Basic~~~wo-SN~0.0.1.0',
        'Language.Basic~~~xh-ZA~0.0.1.0',
        'Language.Basic~~~yo-NG~0.0.1.0',
        'Language.Basic~~~zh-CN~0.0.1.0',
        'Language.Basic~~~zh-HK~0.0.1.0',
        'Language.Basic~~~zh-TW~0.0.1.0',
        'Language.Basic~~~zu-ZA~0.0.1.0',
        'Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Beng~~~und-BENG~0.0.1.0',
        'Language.Fonts.Cans~~~und-CANS~0.0.1.0',
        'Language.Fonts.Cher~~~und-CHER~0.0.1.0',
        'Language.Fonts.Deva~~~und-DEVA~0.0.1.0',
        'Language.Fonts.Ethi~~~und-ETHI~0.0.1.0',
        'Language.Fonts.Gujr~~~und-GUJR~0.0.1.0',
        'Language.Fonts.Guru~~~und-GURU~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Hebr~~~und-HEBR~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Khmr~~~und-KHMR~0.0.1.0',
        'Language.Fonts.Knda~~~und-KNDA~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Laoo~~~und-LAOO~0.0.1.0',
        'Language.Fonts.Mlym~~~und-MLYM~0.0.1.0',
        'Language.Fonts.Orya~~~und-ORYA~0.0.1.0',
        'Language.Fonts.PanEuropeanSupplementalFonts~~~~0.0.1.0',
        'Language.Fonts.Sinh~~~und-SINH~0.0.1.0',
        'Language.Fonts.Syrc~~~und-SYRC~0.0.1.0',
        'Language.Fonts.Taml~~~und-TAML~0.0.1.0',
        'Language.Fonts.Telu~~~und-TELU~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0',
        'Language.Handwriting~~~af-ZA~0.0.1.0',
        'Language.Handwriting~~~bs-LATN-BA~0.0.1.0',
        'Language.Handwriting~~~ca-ES~0.0.1.0',
        'Language.Handwriting~~~cs-CZ~0.0.1.0',
        'Language.Handwriting~~~cy-GB~0.0.1.0',
        'Language.Handwriting~~~da-DK~0.0.1.0',
        'Language.Handwriting~~~de-DE~0.0.1.0',
        'Language.Handwriting~~~el-GR~0.0.1.0',
        'Language.Handwriting~~~en-GB~0.0.1.0',
        'Language.Handwriting~~~en-US~0.0.1.0',
        'Language.Handwriting~~~es-ES~0.0.1.0',
        'Language.Handwriting~~~es-MX~0.0.1.0',
        'Language.Handwriting~~~eu-ES~0.0.1.0',
        'Language.Handwriting~~~fi-FI~0.0.1.0',
        'Language.Handwriting~~~fr-FR~0.0.1.0',
        'Language.Handwriting~~~ga-IE~0.0.1.0',
        'Language.Handwriting~~~gd-GB~0.0.1.0',
        'Language.Handwriting~~~gl-ES~0.0.1.0',
        'Language.Handwriting~~~hi-IN~0.0.1.0',
        'Language.Handwriting~~~hr-HR~0.0.1.0',
        'Language.Handwriting~~~id-ID~0.0.1.0',
        'Language.Handwriting~~~it-IT~0.0.1.0',
        'Language.Handwriting~~~ja-JP~0.0.1.0',
        'Language.Handwriting~~~ko-KR~0.0.1.0',
        'Language.Handwriting~~~lb-LU~0.0.1.0',
        'Language.Handwriting~~~mi-NZ~0.0.1.0',
        'Language.Handwriting~~~ms-BN~0.0.1.0',
        'Language.Handwriting~~~ms-MY~0.0.1.0',
        'Language.Handwriting~~~nb-NO~0.0.1.0',
        'Language.Handwriting~~~nl-NL~0.0.1.0',
        'Language.Handwriting~~~nn-NO~0.0.1.0',
        'Language.Handwriting~~~nso-ZA~0.0.1.0',
        'Language.Handwriting~~~pl-PL~0.0.1.0',
        'Language.Handwriting~~~pt-BR~0.0.1.0',
        'Language.Handwriting~~~pt-PT~0.0.1.0',
        'Language.Handwriting~~~rm-CH~0.0.1.0',
        'Language.Handwriting~~~ro-RO~0.0.1.0',
        'Language.Handwriting~~~ru-RU~0.0.1.0',
        'Language.Handwriting~~~rw-RW~0.0.1.0',
        'Language.Handwriting~~~sk-SK~0.0.1.0',
        'Language.Handwriting~~~sl-SI~0.0.1.0',
        'Language.Handwriting~~~sq-AL~0.0.1.0',
        'Language.Handwriting~~~sr-CYRL-RS~0.0.1.0',
        'Language.Handwriting~~~sr-LATN-RS~0.0.1.0',
        'Language.Handwriting~~~sv-SE~0.0.1.0',
        'Language.Handwriting~~~sw-KE~0.0.1.0',
        'Language.Handwriting~~~tn-ZA~0.0.1.0',
        'Language.Handwriting~~~tr-TR~0.0.1.0',
        'Language.Handwriting~~~wo-SN~0.0.1.0',
        'Language.Handwriting~~~xh-ZA~0.0.1.0',
        'Language.Handwriting~~~zh-CN~0.0.1.0',
        'Language.Handwriting~~~zh-HK~0.0.1.0',
        'Language.Handwriting~~~zh-TW~0.0.1.0',
        'Language.Handwriting~~~zu-ZA~0.0.1.0',
        'Language.OCR~~~ar-SA~0.0.1.0',
        'Language.OCR~~~bg-BG~0.0.1.0',
        'Language.OCR~~~bs-LATN-BA~0.0.1.0',
        'Language.OCR~~~cs-CZ~0.0.1.0',
        'Language.OCR~~~da-DK~0.0.1.0',
        'Language.OCR~~~de-DE~0.0.1.0',
        'Language.OCR~~~el-GR~0.0.1.0',
        'Language.OCR~~~en-GB~0.0.1.0',
        'Language.OCR~~~en-US~0.0.1.0',
        'Language.OCR~~~es-ES~0.0.1.0',
        'Language.OCR~~~es-MX~0.0.1.0',
        'Language.OCR~~~fi-FI~0.0.1.0',
        'Language.OCR~~~fr-CA~0.0.1.0',
        'Language.OCR~~~fr-FR~0.0.1.0',
        'Language.OCR~~~hr-HR~0.0.1.0',
        'Language.OCR~~~hu-HU~0.0.1.0',
        'Language.OCR~~~it-IT~0.0.1.0',
        'Language.OCR~~~ja-JP~0.0.1.0',
        'Language.OCR~~~ko-KR~0.0.1.0',
        'Language.OCR~~~nb-NO~0.0.1.0',
        'Language.OCR~~~nl-NL~0.0.1.0',
        'Language.OCR~~~pl-PL~0.0.1.0',
        'Language.OCR~~~pt-BR~0.0.1.0',
        'Language.OCR~~~pt-PT~0.0.1.0',
        'Language.OCR~~~ro-RO~0.0.1.0',
        'Language.OCR~~~ru-RU~0.0.1.0',
        'Language.OCR~~~sk-SK~0.0.1.0',
        'Language.OCR~~~sl-SI~0.0.1.0',
        'Language.OCR~~~sr-CYRL-RS~0.0.1.0',
        'Language.OCR~~~sr-LATN-RS~0.0.1.0',
        'Language.OCR~~~sv-SE~0.0.1.0',
        'Language.OCR~~~tr-TR~0.0.1.0',
        'Language.OCR~~~zh-CN~0.0.1.0',
        'Language.OCR~~~zh-HK~0.0.1.0',
        'Language.OCR~~~zh-TW~0.0.1.0',
        'Language.Speech~~~da-DK~0.0.1.0',
        'Language.Speech~~~de-DE~0.0.1.0',
        'Language.Speech~~~en-AU~0.0.1.0',
        'Language.Speech~~~en-CA~0.0.1.0',
        'Language.Speech~~~en-GB~0.0.1.0',
        'Language.Speech~~~en-IN~0.0.1.0',
        'Language.Speech~~~en-US~0.0.1.0',
        'Language.Speech~~~es-ES~0.0.1.0',
        'Language.Speech~~~es-MX~0.0.1.0',
        'Language.Speech~~~fr-CA~0.0.1.0',
        'Language.Speech~~~fr-FR~0.0.1.0',
        'Language.Speech~~~it-IT~0.0.1.0',
        'Language.Speech~~~ja-JP~0.0.1.0',
        'Language.Speech~~~pt-BR~0.0.1.0',
        'Language.Speech~~~zh-CN~0.0.1.0',
        'Language.Speech~~~zh-HK~0.0.1.0',
        'Language.Speech~~~zh-TW~0.0.1.0',
        'Language.TextToSpeech~~~ar-EG~0.0.1.0',
        'Language.TextToSpeech~~~ar-SA~0.0.1.0',
        'Language.TextToSpeech~~~bg-BG~0.0.1.0',
        'Language.TextToSpeech~~~ca-ES~0.0.1.0',
        'Language.TextToSpeech~~~cs-CZ~0.0.1.0',
        'Language.TextToSpeech~~~da-DK~0.0.1.0',
        'Language.TextToSpeech~~~de-AT~0.0.1.0',
        'Language.TextToSpeech~~~de-CH~0.0.1.0',
        'Language.TextToSpeech~~~de-DE~0.0.1.0',
        'Language.TextToSpeech~~~el-GR~0.0.1.0',
        'Language.TextToSpeech~~~en-AU~0.0.1.0',
        'Language.TextToSpeech~~~en-CA~0.0.1.0',
        'Language.TextToSpeech~~~en-GB~0.0.1.0',
        'Language.TextToSpeech~~~en-IE~0.0.1.0',
        'Language.TextToSpeech~~~en-IN~0.0.1.0',
        'Language.TextToSpeech~~~en-US~0.0.1.0',
        'Language.TextToSpeech~~~es-ES~0.0.1.0',
        'Language.TextToSpeech~~~es-MX~0.0.1.0',
        'Language.TextToSpeech~~~fi-FI~0.0.1.0',
        'Language.TextToSpeech~~~fr-CA~0.0.1.0',
        'Language.TextToSpeech~~~fr-CH~0.0.1.0',
        'Language.TextToSpeech~~~fr-FR~0.0.1.0',
        'Language.TextToSpeech~~~he-IL~0.0.1.0',
        'Language.TextToSpeech~~~hi-IN~0.0.1.0',
        'Language.TextToSpeech~~~hr-HR~0.0.1.0',
        'Language.TextToSpeech~~~hu-HU~0.0.1.0',
        'Language.TextToSpeech~~~id-ID~0.0.1.0',
        'Language.TextToSpeech~~~it-IT~0.0.1.0',
        'Language.TextToSpeech~~~ja-JP~0.0.1.0',
        'Language.TextToSpeech~~~ko-KR~0.0.1.0',
        'Language.TextToSpeech~~~ms-MY~0.0.1.0',
        'Language.TextToSpeech~~~nb-NO~0.0.1.0',
        'Language.TextToSpeech~~~nl-BE~0.0.1.0',
        'Language.TextToSpeech~~~nl-NL~0.0.1.0',
        'Language.TextToSpeech~~~pl-PL~0.0.1.0',
        'Language.TextToSpeech~~~pt-BR~0.0.1.0',
        'Language.TextToSpeech~~~pt-PT~0.0.1.0',
        'Language.TextToSpeech~~~ro-RO~0.0.1.0',
        'Language.TextToSpeech~~~ru-RU~0.0.1.0',
        'Language.TextToSpeech~~~sk-SK~0.0.1.0',
        'Language.TextToSpeech~~~sl-SI~0.0.1.0',
        'Language.TextToSpeech~~~sv-SE~0.0.1.0',
        'Language.TextToSpeech~~~ta-IN~0.0.1.0',
        'Language.TextToSpeech~~~th-TH~0.0.1.0',
        'Language.TextToSpeech~~~tr-TR~0.0.1.0',
        'Language.TextToSpeech~~~vi-VN~0.0.1.0',
        'Language.TextToSpeech~~~zh-CN~0.0.1.0',
        'Language.TextToSpeech~~~zh-HK~0.0.1.0',
        'Language.TextToSpeech~~~zh-TW~0.0.1.0',
        'MathRecognizer~~~~0.0.1.0',
        'Media.WindowsMediaPlayer~~~~0.0.12.0',
        'Microsoft.Onecore.StorageManagement~~~~0.0.1.0',
        'Microsoft.WebDriver~~~~0.0.1.0',
        'Microsoft.Windows.MSPaint~~~~0.0.1.0',
        'Microsoft.Windows.Notepad~~~~0.0.1.0',
        'Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0',
        'Microsoft.Windows.StorageManagement~~~~0.0.1.0',
        'Microsoft.Windows.WordPad~~~~0.0.1.0',
        'Msix.PackagingTool.Driver~~~~0.0.1.0',
        'NetFX3~~~~',
        'Network.Irda~~~~0.0.1.0',
        'OneCoreUAP.OneSync~~~~0.0.1.0',
        'OpenSSH.Client~~~~0.0.1.0',
        'OpenSSH.Server~~~~0.0.1.0',
        'Print.Fax.Scan~~~~0.0.1.0',
        'Print.Management.Console~~~~0.0.1.0',
        'RasCMAK.Client~~~~0.0.1.0',
        'RIP.Listener~~~~0.0.1.0',
        'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
        'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
        'Rsat.CertificateServices.Tools~~~~0.0.1.0',
        'Rsat.DHCP.Tools~~~~0.0.1.0',
        'Rsat.Dns.Tools~~~~0.0.1.0',
        'Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0',
        'Rsat.FileServices.Tools~~~~0.0.1.0',
        'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
        'Rsat.IPAM.Client.Tools~~~~0.0.1.0',
        'Rsat.LLDP.Tools~~~~0.0.1.0',
        'Rsat.NetworkController.Tools~~~~0.0.1.0',
        'Rsat.NetworkLoadBalancing.Tools~~~~0.0.1.0',
        'Rsat.RemoteAccess.Management.Tools~~~~0.0.1.0',
        'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0',
        'Rsat.ServerManager.Tools~~~~0.0.1.0',
        'Rsat.Shielded.VM.Tools~~~~0.0.1.0',
        'Rsat.StorageMigrationService.Management.Tools~~~~0.0.1.0',
        'Rsat.StorageReplica.Tools~~~~0.0.1.0',
        'Rsat.SystemInsights.Management.Tools~~~~0.0.1.0',
        'Rsat.VolumeActivation.Tools~~~~0.0.1.0',
        'Rsat.WSUS.Tools~~~~0.0.1.0',
        'SNMP.Client~~~~0.0.1.0',
        'Tools.DeveloperMode.Core~~~~0.0.1.0',
        'Tools.Graphics.DirectX~~~~0.0.1.0',
        'Windows.Client.ShellComponents~~~~0.0.1.0',
        'Windows.Desktop.EMS-SAC.Tools~~~~0.0.1.0',
        'WMI-SNMP-Provider.Client~~~~0.0.1.0',
        'XPS.Viewer~~~~0.0.1.0')


    If ($Winver -eq '2004') { $items = ($Win10_2004_FODs | Out-GridView -Title 'Select Features On Demand' -PassThru) }
    If ($Winver -eq '1909') { $items = ($Win10_1909_FODs | Out-GridView -Title 'Select Features On Demand' -PassThru) }
    If ($Winver -eq '1903') { $items = ($Win10_1903_FODs | Out-GridView -Title 'Select Features On Demand' -PassThru) }
    If ($Winver -eq '1809') {
        if ($WinOS -eq 'Windows 10') { $items = ($Win10_1809_FODs | Out-GridView -Title 'Select Features On Demand' -PassThru) }
        if ($WinOS -eq 'Windows Server') { $items = ($Win10_1809_server_FODs | Out-GridView -Title 'Select Features On Demand' -PassThru) }
    }

    #(Get-ChildItem -path $LPSourceFolder | Select-Object -Property Name | Out-GridView -title "Select Local Experience Packs" -PassThru)

    if ($WinOS -eq 'Windows 11') {
        $items = (Get-ChildItem -Path "$PSScriptRoot\imports\fods\Windows 11\$winver" | Select-Object -Property Name | Out-GridView -Title 'Select Featres' -PassThru)
        foreach ($item in $items) { $WPFCustomLBFOD.Items.Add($item.name) }
    }
    else {

        foreach ($item in $items) { $WPFCustomLBFOD.Items.Add($item) }
    }
}

#Function to apply the selected Langauge Packs to the mounted WIM
Function Install-LanguagePacks {
    Update-Log -data 'Applying Language Packs...' -Class Information

    $WinOS = Get-WindowsType
    $Winver = Get-WinVersionNumber

    if (($WinOS -eq 'Windows 10') -and (($winver -eq '20H2') -or ($winver -eq '21H1') -or ($winver -eq '2009') -or ($winver -eq '21H2') -or ($winver -eq '22H2'))) { $winver = '2004' }

    $mountdir = $WPFMISMountTextBox.text

    $LPSourceFolder = $PSScriptRoot + '\imports\Lang\' + $WinOS + '\' + $winver + '\LanguagePacks\'
    $items = $WPFCustomLBLangPacks.items

    foreach ($item in $items) {
        $source = $LPSourceFolder + $item

        $text = 'Applying ' + $item
        Update-Log -Data $text -Class Information

        try {

            if ($demomode -eq $true) {
                $string = 'Demo mode active - not applying ' + $source
                Update-Log -data $string -Class Warning
            }
            else {
                Add-WindowsPackage -PackagePath $source -Path $mountdir -ErrorAction Stop | Out-Null
                Update-Log -Data 'Injection Successful' -Class Information
            }

        }
        catch {
            Update-Log -Data 'Failed to inject Language Pack' -Class Error
            Update-Log -data $_.Exception.Message -Class Error
        }

    }
    Update-Log -Data 'Language Pack injections complete' -Class Information
}

#Function to apply selected LXPs to the mounted WIM
Function Install-LocalExperiencePack {
    Update-Log -data 'Applying Local Experience Packs...' -Class Information

    $mountdir = $WPFMISMountTextBox.text

    $WinOS = Get-WindowsType
    $Winver = Get-WinVersionNumber

    if (($WinOS -eq 'Windows 10') -and (($winver -eq '20H2') -or ($winver -eq '21H1') -or ($winver -eq '2009') -or ($winver -eq '21H2') -or ($winver -eq '22H2'))) { $winver = '2004' }

    $LPSourceFolder = $PSScriptRoot + '\imports\Lang\' + $WinOS + '\' + $winver + '\localexperiencepack\'
    $items = $WPFCustomLBLEP.items

    foreach ($item in $items) {
        $source = $LPSourceFolder + $item
        $license = Get-Item -Path $source\*.xml
        $file = Get-Item -Path $source\*.appx
        $text = 'Applying ' + $item
        Update-Log -Data $text -Class Information
        try {
            Add-ProvisionedAppxPackage -PackagePath $file -LicensePath $license -Path $mountdir -ErrorAction Stop | Out-Null
            Update-Log -Data 'Injection Successful' -Class Information
        }
        catch {
            Update-Log -data 'Failed to apply Local Experience Pack' -Class Error
            Update-Log -data $_.Exception.Message -Class Error
        }
    }
    Update-Log -Data 'Local Experience Pack injections complete' -Class Information
}

#Function to apply selected FODs to the mounted WIM
Function Install-FeaturesOnDemand {
    Update-Log -data 'Applying Features On Demand...' -Class Information

    $mountdir = $WPFMISMountTextBox.text

    $WinOS = Get-WindowsType
    $Winver = Get-WinVersionNumber

    if (($WinOS -eq 'Windows 10') -and (($winver -eq '20H2') -or ($winver -eq '21H1') -or ($winver -eq '2009') -or ($winver -eq '21H2') -or ($winver -eq '22H2'))) { $winver = '2004' }


    $FODsource = $PSScriptRoot + '\imports\FODs\' + $winOS + '\' + $Winver + '\'
    $items = $WPFCustomLBFOD.items

    foreach ($item in $items) {
        $text = 'Applying ' + $item
        Update-Log -Data $text -Class Information

        try {
            Add-WindowsCapability -Path $mountdir -Name $item -Source $FODsource -ErrorAction Stop | Out-Null
            Update-Log -Data 'Injection Successful' -Class Information
        }
        catch {
            Update-Log -data 'Failed to apply Feature On Demand' -Class Error
            Update-Log -data $_.Exception.Message -Class Error
        }


    }
    Update-Log -Data 'Feature on Demand injections complete' -Class Information
}

#Function to import the selected LP's in to the Imports folder
Function Import-LanguagePacks($Winver, $LPSourceFolder, $WinOS) {
    Update-Log -Data 'Importing Language Packs...' -Class Information

    #Note To Donna - Make a step that checks if $winver -eq 1903, and if so, set $winver to 1909
    if ($winver -eq '1903') {
        Update-Log -Data 'Changing version variable because 1903 and 1909 use the same packages' -Class Information
        $winver = '1909'
    }

    if ((Test-Path -Path $PSScriptRoot\imports\Lang\$WinOS\$winver\LanguagePacks) -eq $False) {
        Update-Log -Data 'Destination folder does not exist. Creating...' -Class Warning
        $path = $PSScriptRoot + '\imports\Lang\' + $WinOS + '\' + $winver + '\LanguagePacks'
        $text = 'Creating folder ' + $path
        Update-Log -data $text -Class Information
        New-Item -Path $PSScriptRoot\imports\Lang\$WinOS\$winver -Name LanguagePacks -ItemType Directory
        Update-Log -Data 'Folder created successfully' -Class Information
    }

    $items = $WPFImportOtherLBList.items
    foreach ($item in $items) {
        $source = $LPSourceFolder + $item
        $text = 'Importing ' + $item
        Update-Log -Data $text -Class Information
        Copy-Item $source -Destination $PSScriptRoot\imports\Lang\$WinOS\$Winver\LanguagePacks -Force
    }
    Update-Log -Data 'Importation Complete' -Class Information
}

#Function to import the selected LXP's into the imports forlder
Function Import-LocalExperiencePack($Winver, $LPSourceFolder, $WinOS) {

    if ($winver -eq '1903') {
        Update-Log -Data 'Changing version variable because 1903 and 1909 use the same packages' -Class Information
        $winver = '1909'
    }

    Update-Log -Data 'Importing Local Experience Packs...' -Class Information

    if ((Test-Path -Path $PSScriptRoot\imports\Lang\$WinOS\$winver\localexperiencepack) -eq $False) {
        Update-Log -Data 'Destination folder does not exist. Creating...' -Class Warning
        $path = $PSScriptRoot + '\imports\Lang\' + $WinOS + '\' + $winver + '\localexperiencepack'
        $text = 'Creating folder ' + $path
        Update-Log -data $text -Class Information
        New-Item -Path $PSScriptRoot\imports\Lang\$WinOS\$winver -Name localexperiencepack -ItemType Directory
        Update-Log -Data 'Folder created successfully' -Class Information
    }

    $items = $WPFImportOtherLBList.items
    foreach ($item in $items) {
        $name = $item
        $source = $LPSourceFolder + $name
        $text = 'Creating destination folder for ' + $item
        Update-Log -Data $text -Class Information

        if ((Test-Path -Path $PSScriptRoot\imports\lang\$WinOS\$winver\localexperiencepack\$name) -eq $False) { New-Item -Path $PSScriptRoot\imports\lang\$WinOS\$winver\localexperiencepack -Name $name -ItemType Directory }
        else {
            $text = 'The folder for ' + $item + ' already exists. Skipping creation...'
            Update-Log -Data $text -Class Warning
        }

        Update-Log -Data 'Copying source to destination folders...' -Class Information
        Get-ChildItem -Path $source | Copy-Item -Destination $PSScriptRoot\imports\Lang\$WinOS\$Winver\LocalExperiencePack\$name -Force
    }
    Update-log -Data 'Importation complete' -Class Information
}

#Function to import the contents of the selected FODs into the imports forlder
Function Import-FeatureOnDemand($Winver, $LPSourceFolder, $WinOS) {

    if ($winver -eq '1903') {
        Update-Log -Data 'Changing version variable because 1903 and 1909 use the same packages' -Class Information
        $winver = '1909'
    }

    $path = $WPFImportOtherTBPath.text
    $text = 'Starting importation of Feature On Demand binaries from ' + $path
    Update-Log -Data $text -Class Information

    $langpacks = Get-ChildItem -Path $LPSourceFolder

    if ((Test-Path -Path $PSScriptRoot\imports\FODs\$WinOS\$Winver) -eq $False) {
        Update-Log -Data 'Destination folder does not exist. Creating...' -Class Warning
        $path = $PSScriptRoot + '\imports\FODs\' + $WinOS + '\' + $winver
        $text = 'Creating folder ' + $path
        Update-Log -data $text -Class Information
        New-Item -Path $PSScriptRoot\imports\fods\$WinOS -Name $winver -ItemType Directory
        Update-Log -Data 'Folder created successfully' -Class Information
    }
    #If Windows 11

    if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 11') {
        $items = $WPFImportOtherLBList.items
        foreach ($item in $items) {
            $source = $LPSourceFolder + $item
            $text = 'Importing ' + $item
            Update-Log -Data $text -Class Information
            Copy-Item $source -Destination $PSScriptRoot\imports\FODs\$WinOS\$Winver\ -Force
        }

    }


    #If not Windows 11
    if ($WPFImportOtherCBWinOS.SelectedItem -ne 'Windows 11') {
        foreach ($langpack in $langpacks) {
            $source = $LPSourceFolder + $langpack.name

            Copy-Item $source -Destination $PSScriptRoot\imports\FODs\$WinOS\$Winver\ -Force
            $name = $langpack.name
            $text = 'Copying ' + $name
            Update-Log -Data $text -Class Information

        }
    }

    Update-Log -Data 'Importing metadata subfolder...' -Class Information
    Get-ChildItem -Path ($LPSourceFolder + '\metadata\') | Copy-Item -Destination $PSScriptRoot\imports\FODs\$WinOS\$Winver\metadata -Force
    Update-Log -data 'Feature On Demand imporation complete.'
}

#Function to update winver cobmo box
Function Update-ImportVersionCB {
    $WPFImportOtherCBWinVer.Items.Clear()
    if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows Server') { Foreach ($WinSrvVer in $WinSrvVer) { $WPFImportOtherCBWinVer.Items.Add($WinSrvVer) } }
    if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 10') { Foreach ($Win10Ver in $Win10ver) { $WPFImportOtherCBWinVer.Items.Add($Win10Ver) } }
    if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 11') { Foreach ($Win11Ver in $Win11ver) { $WPFImportOtherCBWinVer.Items.Add($Win11Ver) } }
}

#Function to select other object import source path
Function Select-ImportOtherPath {
    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Source folder'
    $null = $browser.ShowDialog()
    $ImportPath = $browser.SelectedPath + '\'
    $WPFImportOtherTBPath.text = $ImportPath

}

#Function to allow user to pause MAke it so process
Function Suspend-MakeItSo {
    $MISPause = ([System.Windows.MessageBox]::Show('Click Yes to continue the image build. Click No to cancel and discard the wim file.', 'WIM Witch Paused', 'YesNo', 'Warning'))
    if ($MISPause -eq 'Yes') { return 'Yes' }

    if ($MISPause -eq 'No') { return 'No' }
}

#Function to run a powershell script with supplied paramenters
Function Start-Script($file, $parameter) {
    $string = "$file $parameter"
    try {
        Update-Log -Data 'Running script' -Class Information
        Invoke-Expression -Command $string -ErrorAction Stop
        Update-Log -data 'Script complete' -Class Information
    }
    catch {
        Update-Log -Data 'Script failed' -Class Error
    }
}

#Function to select existing configMgr image package
Function Get-ImageInfo {
    Param(
        [parameter(mandatory = $true)]
        [string]$PackID

    )


    #set-ConfigMgrConnection
    Set-Location $CMDrive
    $image = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_ImagePackage -ComputerName $global:SiteServer) | Where-Object { ($_.PackageID -eq $PackID) }

    $WPFCMTBImageName.text = $image.name
    $WPFCMTBWinBuildNum.text = $image.ImageOSversion
    $WPFCMTBPackageID.text = $image.PackageID
    $WPFCMTBImageVer.text = $image.version
    $WPFCMTBDescription.text = $image.Description

    $text = 'Image ' + $WPFCMTBImageName.text + ' selected'
    Update-Log -data $text -class Information

    $text = 'Package ID is ' + $image.PackageID
    Update-Log -data $text -class Information

    $text = 'Image build number is ' + $image.ImageOSversion
    Update-Log -data $text -class Information

    $packageID = (Get-CMOperatingSystemImage -Id $image.PackageID)
    # $packageID.PkgSourcePath

    $WPFMISWimFolderTextBox.text = (Split-Path -Path $packageID.PkgSourcePath)
    $WPFMISWimNameTextBox.text = (Split-Path -Path $packageID.PkgSourcePath -Leaf)

    $Package = $packageID.PackageID
    $DPs = Get-CMDistributionPoint
    $NALPaths = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -ComputerName $global:SiteServer -Query "SELECT * FROM SMS_DistributionPoint WHERE PackageID='$Package'")

    Update-Log -Data 'Retrieving Distrbution Point Information' -Class Information
    foreach ($NALPath in $NALPaths) {
        foreach ($dp in $dps) {
            $DPPath = $dp.NetworkOSPath
            if ($NALPath.ServerNALPath -like ("*$DPPath*")) {
                Update-Log -data "Image has been previously distributed to $DPPath" -class Information
                $WPFCMLBDPs.Items.Add($DPPath)

            }
        }
    }

    #Detect Binary Diff Replication
    Update-Log -data 'Checking Binary Differential Replication setting' -Class Information
    if ($image.PkgFlags -eq ($image.PkgFlags -bor 0x04000000)) {
        $WPFCMCBBinDirRep.IsChecked = $True
    }
    else {
        $WPFCMCBBinDirRep.IsChecked = $False
    }

    #Detect Package Share Enabled
    Update-Log -data 'Checking package share settings' -Class Information
    if ($image.PkgFlags -eq ($image.PkgFlags -bor 0x80)) {
        $WPFCMCBDeploymentShare.IsChecked = $true
    }
    else
    { $WPFCMCBDeploymentShare.IsChecked = $false }

    Set-Location $PSScriptRoot
}

#Function to select DP's from ConfigMgr
Function Select-DistributionPoints {
    #set-ConfigMgrConnection
    Set-Location $CMDrive

    if ($WPFCMCBDPDPG.SelectedItem -eq 'Distribution Points') {

        $SelectedDPs = (Get-CMDistributionPoint -SiteCode $global:sitecode).NetworkOSPath | Out-GridView -Title 'Select Distribution Points' -PassThru
        foreach ($SelectedDP in $SelectedDPs) { $WPFCMLBDPs.Items.Add($SelectedDP) }
    }
    if ($WPFCMCBDPDPG.SelectedItem -eq 'Distribution Point Groups') {
        $SelectedDPs = (Get-CMDistributionPointGroup).Name | Out-GridView -Title 'Select Distribution Point Groups' -PassThru
        foreach ($SelectedDP in $SelectedDPs) { $WPFCMLBDPs.Items.Add($SelectedDP) }
    }
    Set-Location $PSScriptRoot
}

#Function to create the new image in ConfigMgr
Function New-CMImagePackage {
    #set-ConfigMgrConnection
    Set-Location $CMDrive
    $Path = $WPFMISWimFolderTextBox.text + '\' + $WPFMISWimNameTextBox.text

    try {
        New-CMOperatingSystemImage -Name $WPFCMTBImageName.text -Path $Path -ErrorAction Stop
        Update-Log -data 'Image was created. Check ConfigMgr console' -Class Information
    }
    catch {
        Update-Log -data 'Failed to create the image' -Class Error
        Update-Log -data $_.Exception.Message -Class Error
    }

    $PackageID = (Get-CMOperatingSystemImage -Name $WPFCMTBImageName.text).PackageID
    Update-Log -Data "The Package ID of the new image is $PackageID" -Class Information

    Set-ImageProperties -PackageID $PackageID

    Update-Log -Data 'Retriveing Distribution Point information...' -Class Information
    $DPs = $WPFCMLBDPs.Items

    foreach ($DP in $DPs) {
        # Hello! This line was written on 3/3/2020.
        $DP = $DP -replace '\\', ''

        Update-Log -Data 'Distributiong image package content...' -Class Information
        if ($WPFCMCBDPDPG.SelectedItem -eq 'Distribution Points') {
            Start-CMContentDistribution -OperatingSystemImageId $PackageID -DistributionPointName $DP
        }
        if ($WPFCMCBDPDPG.SelectedItem -eq 'Distribution Point Groups') {
            Start-CMContentDistribution -OperatingSystemImageId $PackageID -DistributionPointGroupName $DP
        }

        Update-Log -Data 'Content has been distributed.' -Class Information
    }

    Save-Configuration -CM $PackageID
    Set-Location $PSScriptRoot
}

#Function to enable/disable options on ConfigMgr tab
Function Enable-ConfigMgrOptions {

    #"Disabled","New Image","Update Existing Image"
    if ($WPFCMCBImageType.SelectedItem -eq 'New Image') {
        $WPFCMBAddDP.IsEnabled = $True
        $WPFCMBRemoveDP.IsEnabled = $True
        $WPFCMBSelectImage.IsEnabled = $False
        $WPFCMCBBinDirRep.IsEnabled = $True
        $WPFCMCBDPDPG.IsEnabled = $True
        $WPFCMLBDPs.IsEnabled = $True
        $WPFCMTBDescription.IsEnabled = $True
        $WPFCMTBImageName.IsEnabled = $True
        $WPFCMTBImageVer.IsEnabled = $True
        $WPFCMTBPackageID.IsEnabled = $False
        #        $WPFCMTBSitecode.IsEnabled = $True
        #        $WPFCMTBSiteServer.IsEnabled = $True
        $WPFCMTBWinBuildNum.IsEnabled = $False
        $WPFCMCBImageVerAuto.IsEnabled = $True
        $WPFCMCBDescriptionAuto.IsEnabled = $True
        $WPFCMCBDeploymentShare.IsEnabled = $True


        # $MEMCMsiteinfo = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification"
        # $WPFCMTBSiteServer.text = $MEMCMsiteinfo.'Site Server'
        # $WPFCMTBSitecode.text = $MEMCMsiteinfo.'Site Code'
        Update-Log -data 'ConfigMgr feature enabled. New Image selected' -class Information
        #    Update-Log -data $WPFCMTBSitecode.text -class Information
        #    Update-Log -data $WPFCMTBSiteServer.text -class Information
    }

    if ($WPFCMCBImageType.SelectedItem -eq 'Update Existing Image') {
        $WPFCMBAddDP.IsEnabled = $False
        $WPFCMBRemoveDP.IsEnabled = $False
        $WPFCMBSelectImage.IsEnabled = $True
        $WPFCMCBBinDirRep.IsEnabled = $True
        $WPFCMCBDPDPG.IsEnabled = $False
        $WPFCMLBDPs.IsEnabled = $False
        $WPFCMTBDescription.IsEnabled = $True
        $WPFCMTBImageName.IsEnabled = $False
        $WPFCMTBImageVer.IsEnabled = $True
        $WPFCMTBPackageID.IsEnabled = $True
        $WPFCMTBSitecode.IsEnabled = $True
        $WPFCMTBSiteServer.IsEnabled = $True
        $WPFCMTBWinBuildNum.IsEnabled = $False
        $WPFCMCBImageVerAuto.IsEnabled = $True
        $WPFCMCBDescriptionAuto.IsEnabled = $True
        $WPFCMCBDeploymentShare.IsEnabled = $True

        #  $MEMCMsiteinfo = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification"
        #  $WPFCMTBSiteServer.text = $MEMCMsiteinfo.'Site Server'
        #  $WPFCMTBSitecode.text = $MEMCMsiteinfo.'Site Code'
        Update-Log -data 'ConfigMgr feature enabled. Update an existing image selected' -class Information
        #   Update-Log -data $WPFCMTBSitecode.text -class Information
        #   Update-Log -data $WPFCMTBSiteServer.text -class Information
    }

    if ($WPFCMCBImageType.SelectedItem -eq 'Disabled') {
        $WPFCMBAddDP.IsEnabled = $False
        $WPFCMBRemoveDP.IsEnabled = $False
        $WPFCMBSelectImage.IsEnabled = $False
        $WPFCMCBBinDirRep.IsEnabled = $False
        $WPFCMCBDPDPG.IsEnabled = $False
        $WPFCMLBDPs.IsEnabled = $False
        $WPFCMTBDescription.IsEnabled = $False
        $WPFCMTBImageName.IsEnabled = $False
        $WPFCMTBImageVer.IsEnabled = $False
        $WPFCMTBPackageID.IsEnabled = $False
        #       $WPFCMTBSitecode.IsEnabled = $False
        #       $WPFCMTBSiteServer.IsEnabled = $False
        $WPFCMTBWinBuildNum.IsEnabled = $False
        $WPFCMCBImageVerAuto.IsEnabled = $False
        $WPFCMCBDescriptionAuto.IsEnabled = $False
        $WPFCMCBDeploymentShare.IsEnabled = $False
        Update-Log -data 'ConfigMgr feature disabled' -class Information

    }

}

#Function to update DP's when updating existing image file in ConfigMgr
Function Update-CMImage {
    #set-ConfigMgrConnection
    Set-Location $CMDrive
    $wmi = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_ImagePackage -ComputerName $global:SiteServer) | Where-Object { $_.PackageID -eq $WPFCMTBPackageID.text }



    Update-Log -Data 'Updating images on the Distribution Points...'
    $WMI.RefreshPkgSource() | Out-Null

    Update-Log -Data 'Refreshing image proprties from the WIM' -Class Information
    $WMI.ReloadImageProperties() | Out-Null

    Set-ImageProperties -PackageID $WPFCMTBPackageID.Text
    Save-Configuration -CM -filename $WPFCMTBPackageID.Text

    Set-Location $PSScriptRoot
}

#Function to enable disable & options on the Software Update Catalog tab
Function Invoke-UpdateTabOptions {

    if ($WPFUSCBSelectCatalogSource.SelectedItem -eq 'None' ) {

        $WPFUpdateOSDBUpdateButton.IsEnabled = $false
        $WPFUpdatesDownloadNewButton.IsEnabled = $false
        $WPFUpdatesW10Main.IsEnabled = $false
        $WPFUpdatesS2019.IsEnabled = $false
        $WPFUpdatesS2016.IsEnabled = $false

        $WPFMISCBCheckForUpdates.IsEnabled = $false
        $WPFMISCBCheckForUpdates.IsChecked = $false

    }

    if ($WPFUSCBSelectCatalogSource.SelectedItem -eq 'OSDSUS') {
        $WPFUpdateOSDBUpdateButton.IsEnabled = $true
        $WPFUpdatesDownloadNewButton.IsEnabled = $true
        $WPFUpdatesW10Main.IsEnabled = $true
        $WPFUpdatesS2019.IsEnabled = $true
        $WPFUpdatesS2016.IsEnabled = $true

        $WPFMISCBCheckForUpdates.IsEnabled = $false
        $WPFMISCBCheckForUpdates.IsChecked = $false
        Update-Log -data 'OSDSUS selected as update catalog' -class Information
        Invoke-OSDCheck

    }

    if ($WPFUSCBSelectCatalogSource.SelectedItem -eq 'ConfigMgr') {
        $WPFUpdateOSDBUpdateButton.IsEnabled = $false
        $WPFUpdatesDownloadNewButton.IsEnabled = $true
        $WPFUpdatesW10Main.IsEnabled = $true
        $WPFUpdatesS2019.IsEnabled = $true
        $WPFUpdatesS2016.IsEnabled = $true
        $WPFMISCBCheckForUpdates.IsEnabled = $true
        #        $MEMCMsiteinfo = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification"

        #   $WPFCMTBSiteServer.text = $MEMCMsiteinfo.'Site Server'
        #   $WPFCMTBSitecode.text = $MEMCMsiteinfo.'Site Code'
        Update-Log -data 'ConfigMgr is selected as the update catalog' -Class Information

    }

}

Function Invoke-MSUpdateItemDownload {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true, HelpMessage = 'Specify the path to where the update item will be downloaded.')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        $UpdateName
    )
    #write-host $updatename
    #write-host $filepath

    $OptionalUpdateCheck = 0

    #Adding in optional updates


    if ($UpdateName -like '*Adobe*') {
        $UpdateClass = 'AdobeSU'
        $OptionalUpdateCheck = 1
    }
    if ($UpdateName -like '*Microsoft .NET Framework*') {
        $UpdateClass = 'DotNet'
        $OptionalUpdateCheck = 1
    }
    if ($UpdateName -like '*Cumulative Update for .NET Framework*') {
        $OptionalUpdateCheck = 1
        $UpdateClass = 'DotNetCU'
    }
    if ($UpdateName -like '*Cumulative Update for Windows*') {
        $UpdateClass = 'LCU'
        $OptionalUpdateCheck = 1
    }
    if ($UpdateName -like '*Cumulative Update for Microsoft*') {
        $UpdateClass = 'LCU'
        $OptionalUpdateCheck = 1
    }
    if ($UpdateName -like '*Servicing Stack Update*') {
        $OptionalUpdateCheck = 1
        $UpdateClass = 'SSU'
    }
    if ($UpdateName -like '*Dynamic*') {
        $OptionalUpdateCheck = 1
        $UpdateClass = 'Dynamic'
    }

    if ($OptionalUpdateCheck -eq '0') {

        #Update-Log -data "This update appears to be optional. Skipping..." -Class Warning
        #return
        if ($WPFUpdatesCBEnableOptional.IsChecked -eq $True) { Update-Log -data 'This update appears to be optional. Downloading...' -Class Information }
        else {
            Update-Log -data 'This update appears to be optional, but are not enabled for download. Skipping...' -Class Information
            return
        }
        #Update-Log -data "This update appears to be optional. Downloading..." -Class Information

        $UpdateClass = 'Optional'

    }

    if ($UpdateName -like '*Windows 10*') {
        #here
        #if (($UpdateName -like "* 1903 *") -or ($UpdateName -like "* 1909 *") -or ($UpdateName -like "* 2004 *") -or ($UpdateName -like "* 20H2 *") -or ($UpdateName -like "* 21H1 *") -or ($UpdateName -like "* 21H2 *") -or ($UpdateName -like "* 22H2 *")){$WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'"}

        if (($UpdateName -like '* 1903 *') -or ($UpdateName -like '* 1909 *') -or ($UpdateName -like '* 2004 *') -or ($UpdateName -like '* 20H2 *') -or ($UpdateName -like '* 21H1 *') -or ($UpdateName -like '* 21H2 *') -or ($UpdateName -like '* 22H2 *')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'" }
        else { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10'" }
        if ($updateName -like '*Dynamic*') {
            if ($WPFUpdatesCBEnableDynamic.IsChecked -eq $True) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10 Dynamic Update'" }
        }
        #else{
        #Update-Log -data "Dynamic updates have not been selected for downloading. Skipping..." -Class Information
        #return
        #}
    }

    if ($UpdateName -like '*Windows 11*') {
        { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 11'" }

        if ($updateName -like '*Dynamic*') {
            if ($WPFUpdatesCBEnableDynamic.IsChecked -eq $True) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 11 Dynamic Update'" }
        }

    }



    if (($UpdateName -like '*Windows Server*') -and ($ver -eq '1607')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2016'" }
    if (($UpdateName -like '*Windows Server*') -and ($ver -eq '1809')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2019'" }
    if (($UpdateName -like '*Windows Server*') -and ($ver -eq '21H2')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Microsoft Server operating system-21H2'" }


    $UpdateItem = Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.LocalizedDisplayName -eq $UpdateName) }

    if ($null -ne $UpdateItem) {

        # Determine the ContentID instances associated with the update instance
        $UpdateItemContentIDs = Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_CIToContent -ComputerName $global:SiteServer -Filter "CI_ID = $($UpdateItem.CI_ID)" -ErrorAction Stop
        if ($null -ne $UpdateItemContentIDs) {

            # Account for multiple content ID items
            foreach ($UpdateItemContentID in $UpdateItemContentIDs) {
                # Get the content files associated with current Content ID
                $UpdateItemContent = Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_CIContentFiles -ComputerName $global:SiteServer -Filter "ContentID = $($UpdateItemContentID.ContentID)" -ErrorAction Stop
                if ($null -ne $UpdateItemContent) {
                    # Create new custom object for the update content
                    #write-host $UpdateItemContent.filename
                    $PSObject = [PSCustomObject]@{
                        'DisplayName' = $UpdateItem.LocalizedDisplayName
                        'ArticleID'   = $UpdateItem.ArticleID
                        'FileName'    = $UpdateItemContent.filename
                        'SourceURL'   = $UpdateItemContent.SourceURL
                        'DateRevised' = [System.Management.ManagementDateTimeConverter]::ToDateTime($UpdateItem.DateRevised)
                    }

                    $variable = $FilePath + $UpdateClass + '\' + $UpdateName

                    if ((Test-Path -Path $variable) -eq $false) {
                        Update-Log -Data "Creating folder $variable" -Class Information
                        New-Item -Path $variable -ItemType Directory | Out-Null
                        Update-Log -data 'Created folder' -Class Information
                    }
                    else {
                        $testpath = $variable + '\' + $PSObject.FileName

                        if ((Test-Path -Path $testpath) -eq $true) {
                            Update-Log -Data 'Update already exists. Skipping the download...' -Class Information
                            return
                        }
                    }

                    try {
                        Update-Log -Data "Downloading update item content from: $($PSObject.SourceURL)" -Class Information

                        $DNLDPath = $variable + '\' + $PSObject.FileName

                        $WebClient = New-Object -TypeName System.Net.WebClient
                        $WebClient.DownloadFile($PSObject.SourceURL, $DNLDPath)

                        Update-Log -Data "Download completed successfully, renamed file to: $($PSObject.FileName)" -Class Information
                        $ReturnValue = 0
                    }
                    catch [System.Exception] {
                        Update-Log -data "Unable to download update item content. Error message: $($_.Exception.Message)" -Class Error
                        $ReturnValue = 1
                    }
                }
                else {
                    Update-Log -data "Unable to determine update content instance for CI_ID: $($UpdateItemContentID.ContentID)" -Class Error
                    $ReturnValue = 1
                }
            }
        }
        else {
            Update-Log -Data "Unable to determine ContentID instance for CI_ID: $($UpdateItem.CI_ID)" -Class Error
            $ReturnValue = 1
        }
    }
    else {
        Update-Log -data "Unable to locate update item from SMS Provider for update type: $($UpdateType)" -Class Error
        $ReturnValue = 2
    }


    # Handle return value from Function
    return $ReturnValue | Out-Null
}

#Function to check for updates against ConfigMgr
Function Invoke-MEMCMUpdatecatalog($prod, $ver) {

    #set-ConfigMgrConnection
    Set-Location $CMDrive
    $Arch = 'x64'

    if ($prod -eq 'Windows 10') {
        #        if (($ver -ge '1903') -or ($ver -eq "21H1")){$WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'"}
        #        if (($ver -ge '1903') -or ($ver -eq "21H1") -or ($ver -eq "20H2") -or ($ver -eq "21H2") -or ($ver -eq "22H2")){$WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'"}
        #here
        if (($ver -ge '1903') -or ($ver -like '2*')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'" }


        if ($ver -le '1809') { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10'" }

        $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($ver)*$($Arch)*") } )
    }


    if (($prod -like '*Windows Server*') -and ($ver -eq '1607')) {
        $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2016'"
        $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -notlike '* Next *') -and ($_.LocalizedDisplayName -notlike '*(1703)*') -and ($_.LocalizedDisplayName -notlike '*(1709)*') -and ($_.LocalizedDisplayName -notlike '*(1803)*') })
    }

    if (($prod -like '*Windows Server*') -and ($ver -eq '1809')) {
        $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2019'"
        $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($Arch)*") } )
    }

    if (($prod -like '*Windows Server*') -and ($ver -eq '21H2')) {
        $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Microsoft Server operating system-21H2'"
        $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($Arch)*") } )
    }

    if ($prod -eq 'Windows 11') {
        $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 11'"
        #$Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($Arch)*") } )
        if ($ver -eq '21H2') { $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*Windows 11 for $($Arch)*") } ) }
        else { $Updates = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($ver)*$($Arch)*") } ) }


    }

    if ($WPFUpdatesCBEnableDynamic.IsChecked -eq $True) {

        if ($prod -eq 'Windows 10') { $Updates = $Updates + (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter "LocalizedCategoryInstanceNames = 'Windows 10 Dynamic Update'" -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$($ver)*$($Arch)*") } ) }
        if ($prod -eq 'Windows 11') { $Updates = $Updates + (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter "LocalizedCategoryInstanceNames = 'Windows 11 Dynamic Update'" -ErrorAction Stop | Where-Object { ($_.IsSuperseded -eq $false) -and ($_.LocalizedDisplayName -like "*$prod*") -and ($_.LocalizedDisplayName -like "*$arch*") } ) }


    }


    if ($null -eq $updates) {
        Update-Log -data 'No updates found. Product is likely not synchronized. Continuing with build...' -class Warning
        Set-Location $PSScriptRoot
        return
    }


    foreach ($update in $updates) {
        if ((($update.localizeddisplayname -notlike 'Feature update*') -and ($update.localizeddisplayname -notlike 'Upgrade to Windows 11*' )) -and ($update.localizeddisplayname -notlike '*Language Pack*') -and ($update.localizeddisplayname -notlike '*editions),*')) {
            Update-Log -Data 'Checking the following update:' -Class Information
            Update-Log -data $update.localizeddisplayname -Class Information
            #write-host "Display Name"
            #write-host $update.LocalizedDisplayName
            #            if ($ver -eq  "20H2"){$ver = "2009"} #Another 20H2 naming work around
            Invoke-MSUpdateItemDownload -FilePath "$PSScriptRoot\updates\$Prod\$ver\" -UpdateName $update.LocalizedDisplayName
        }
    }

    Set-Location $PSScriptRoot
}

#Function to check for supersedence against ConfigMgr
Function Invoke-MEMCMUpdateSupersedence($prod, $Ver) {
    #set-ConfigMgrConnection
    Set-Location $CMDrive
    $Arch = 'x64'

    if (($prod -eq 'Windows 10') -and (($ver -ge '1903') -or ($ver -eq '20H2') -or ($ver -eq '21H1') -or ($ver -eq '21H2')  )) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10, version 1903 and later'" }
    if (($prod -eq 'Windows 10') -and ($ver -le '1809')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows 10'" }
    if (($prod -eq 'Windows Server') -and ($ver = '1607')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2016'" }
    if (($prod -eq 'Windows Server') -and ($ver -eq '1809')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Windows Server 2019'" }
    if (($prod -eq 'Windows Server') -and ($ver -eq '21H2')) { $WMIQueryFilter = "LocalizedCategoryInstanceNames = 'Microsoft Server operating system-21H2'" }

    Update-Log -data 'Checking files for supersedense...' -Class Information

    if ((Test-Path -Path "$PSScriptRoot\updates\$Prod\$ver\") -eq $False) {
        Update-Log -Data 'Folder doesnt exist. Skipping supersedence check...' -Class Warning
        return
    }

    #For every folder under updates\prod\ver
    $FolderFirstLevels = Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\"
    foreach ($FolderFirstLevel in $FolderFirstLevels) {

        #For every folder under updates\prod\ver\class
        $FolderSecondLevels = Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel"
        foreach ($FolderSecondLevel in $FolderSecondLevels) {

            #for every cab under updates\prod\ver\class\update
            $UpdateCabs = (Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel\$FolderSecondLevel")
            foreach ($UpdateCab in $UpdateCabs) {
                Update-Log -data "Checking update file name $UpdateCab" -Class Information
                $UpdateItem = Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $global:SiteServer -Filter $WMIQueryFilter -ErrorAction Stop | Where-Object { ($_.LocalizedDisplayName -eq $FolderSecondLevel) }

                if ($UpdateItem.IsSuperseded -eq $false) {

                    Update-Log -data "Update $FolderSecondLevel is current" -Class Information
                }
                else {
                    Update-Log -Data "Update $UpdateCab is superseded. Deleting file..." -Class Warning
                    Remove-Item -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel\$FolderSecondLevel\$UpdateCab"
                }
            }
        }
    }

    Update-Log -Data 'Cleaning folders...' -Class Information
    $FolderFirstLevels = Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\"
    foreach ($FolderFirstLevel in $FolderFirstLevels) {

        #For every folder under updates\prod\ver\class
        $FolderSecondLevels = Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel"
        foreach ($FolderSecondLevel in $FolderSecondLevels) {

            #for every cab under updates\prod\ver\class\update
            $UpdateCabs = (Get-ChildItem -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel\$FolderSecondLevel")

            if ($null -eq $UpdateCabs) {
                Update-Log -Data "$FolderSecondLevel is empty. Deleting...." -Class Warning
                Remove-Item -Path "$PSScriptRoot\updates\$Prod\$ver\$FolderFirstLevel\$FolderSecondLevel"
            }
        }
    }

    Set-Location $PSSCriptRoot
    Update-Log -data 'Supersedence check complete' -class Information
}

#Function to update source from ConfigMgr when Making It So
Function Invoke-MISUpdates {

    $OS = get-Windowstype
    $ver = Get-WinVersionNumber

    if ($ver -eq '2009') { $ver = '20H2' }

    Invoke-MEMCMUpdateSupersedence -prod $OS -Ver $ver
    Invoke-MEMCMUpdatecatalog -prod $OS -ver $ver

    #fucking 2009 to 20h2

}

#Function to run the osdsus and osdupdate update check Functions
Function Invoke-OSDCheck {

    Get-OSDBInstallation #Sets OSDUpate version info
    Get-OSDBCurrentVer #Discovers current version of OSDUpdate
    Compare-OSDBuilderVer #determines if an update of OSDUpdate can be applied
    get-osdsusinstallation #Sets OSDSUS version info
    Get-OSDSUSCurrentVer #Discovers current version of OSDSUS
    Compare-OSDSUSVer #determines if an update of OSDSUS can be applied
}

#Function to update image version, properties, and binary delta replication
Function Set-ImageProperties($PackageID) {
    #write-host $PackageID
    #set-ConfigMgrConnection
    Set-Location $CMDrive

    #Version Text Box
    if ($WPFCMCBImageVerAuto.IsChecked -eq $true) {
        $string = 'Built ' + (Get-Date -DisplayHint Date)
        Update-Log -Data "Updating image version to $string" -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -Version $string
    }

    if ($WPFCMCBImageVerAuto.IsChecked -eq $false) {

        if ($null -ne $WPFCMTBImageVer.text) {
            Update-Log -Data 'Updating version of the image...' -Class Information
            Set-CMOperatingSystemImage -Id $PackageID -Version $WPFCMTBImageVer.text
        }
    }

    #Description Text Box
    if ($WPFCMCBDescriptionAuto.IsChecked -eq $true) {
        $string = 'This image contains the following customizations: '
        if ($WPFUpdatesEnableCheckBox.IsChecked -eq $true) { $string = $string + 'Software Updates, ' }
        if ($WPFCustomCBLangPacks.IsChecked -eq $true) { $string = $string + 'Language Packs, ' }
        if ($WPFCustomCBLEP.IsChecked -eq $true) { $string = $string + 'Local Experience Packs, ' }
        if ($WPFCustomCBFOD.IsChecked -eq $true) { $string = $string + 'Features on Demand, ' }
        if ($WPFMISDotNetCheckBox.IsChecked -eq $true) { $string = $string + '.Net 3.5, ' }
        if ($WPFMISOneDriveCheckBox.IsChecked -eq $true) { $string = $string + 'OneDrive Consumer, ' }
        if ($WPFAppxCheckBox.IsChecked -eq $true) { $string = $string + 'APPX Removal, ' }
        if ($WPFDriverCheckBox.IsChecked -eq $true) { $string = $string + 'Drivers, ' }
        if ($WPFJSONEnableCheckBox.IsChecked -eq $true) { $string = $string + 'Autopilot, ' }
        if ($WPFCustomCBRunScript.IsChecked -eq $true) { $string = $string + 'Custom Script, ' }
        Update-Log -data 'Setting image description...' -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -Description $string
    }

    if ($WPFCMCBDescriptionAuto.IsChecked -eq $false) {

        if ($null -ne $WPFCMTBDescription.Text) {
            Update-Log -Data 'Updating description of the image...' -Class Information
            Set-CMOperatingSystemImage -Id $PackageID -Description $WPFCMTBDescription.Text
        }
    }

    #Check Box properties
    #Binary Differnential Replication
    if ($WPFCMCBBinDirRep.IsChecked -eq $true) {
        Update-Log -Data 'Enabling Binary Differential Replication' -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -EnableBinaryDeltaReplication $true
    }
    else {
        Update-Log -Data 'Disabling Binary Differential Replication' -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -EnableBinaryDeltaReplication $false
    }

    #Package Share
    if ($WPFCMCBDeploymentShare.IsChecked -eq $true) {
        Update-Log -Data 'Enabling Package Share' -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -CopyToPackageShareOnDistributionPoint $true
    }
    else {
        Update-Log -Data 'Disabling Package Share' -Class Information
        Set-CMOperatingSystemImage -Id $PackageID -CopyToPackageShareOnDistributionPoint $false
    }


}

#Function to detect and set CM site properties
Function Find-ConfigManager() {

    If ((Test-Path -Path HKLM:\SOFTWARE\Microsoft\SMS\Identification) -eq $true) {
        Update-Log -Data 'Site Information found in Registry' -Class Information
        try {

            $MEMCMsiteinfo = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification' -ErrorAction Stop

            $WPFCMTBSiteServer.text = $MEMCMsiteinfo.'Site Server'
            $WPFCMTBSitecode.text = $MEMCMsiteinfo.'Site Code'

            #$WPFCMTBSiteServer.text = "nt-tpmemcm.notorious.local"
            #$WPFCMTBSitecode.text = "NTP"

            $global:SiteCode = $WPFCMTBSitecode.text
            $global:SiteServer = $WPFCMTBSiteServer.Text
            $global:CMDrive = $WPFCMTBSitecode.text + ':'

            Update-Log -Data 'ConfigMgr detected and properties set' -Class Information
            Update-Log -Data 'ConfigMgr feature enabled' -Class Information
            $sitecodetext = 'Site Code - ' + $WPFCMTBSitecode.text
            Update-Log -Data $sitecodetext -Class Information
            $siteservertext = 'Site Server - ' + $WPFCMTBSiteServer.text
            Update-Log -Data $siteservertext -Class Information
            if ($CM -eq 'New') {
                $WPFCMCBImageType.SelectedIndex = 1
                Enable-ConfigMgrOptions
            }

            return 0
        }
        catch {
            Update-Log -Data 'ConfigMgr not detected' -Class Information
            $WPFCMTBSiteServer.text = 'Not Detected'
            $WPFCMTBSitecode.text = 'Not Detected'
            return 1
        }
    }

    if ((Test-Path -Path $PSScriptRoot\ConfigMgr\SiteInfo.XML) -eq $true) {
        Update-Log -data 'ConfigMgr Site info XML found' -class Information

        $settings = Import-Clixml -Path $PSScriptRoot\ConfigMgr\SiteInfo.xml -ErrorAction Stop

        $WPFCMTBSitecode.text = $settings.SiteCode
        $WPFCMTBSiteServer.text = $settings.SiteServer

        Update-Log -Data 'ConfigMgr detected and properties set' -Class Information
        Update-Log -Data 'ConfigMgr feature enabled' -Class Information
        $sitecodetext = 'Site Code - ' + $WPFCMTBSitecode.text
        Update-Log -Data $sitecodetext -Class Information
        $siteservertext = 'Site Server - ' + $WPFCMTBSiteServer.text
        Update-Log -Data $siteservertext -Class Information

        return 0
    }

    Update-Log -Data 'ConfigMgr not detected' -Class Information
    $WPFCMTBSiteServer.text = 'Not Detected'
    $WPFCMTBSitecode.text = 'Not Detected'
    Return 1

}

#Function to manually set the CM site properties
Function Set-ConfigMgr() {

    try {

        # $MEMCMsiteinfo = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Identification" -ErrorAction Stop

        # $WPFCMTBSiteServer.text = $MEMCMsiteinfo.'Site Server'
        # $WPFCMTBSitecode.text = $MEMCMsiteinfo.'Site Code'

        #$WPFCMTBSiteServer.text = "nt-tpmemcm.notorious.local"
        #$WPFCMTBSitecode.text = "NTP"

        $global:SiteCode = $WPFCMTBSitecode.text
        $global:SiteServer = $WPFCMTBSiteServer.Text
        $global:CMDrive = $WPFCMTBSitecode.text + ':'

        Update-Log -Data 'ConfigMgr detected and properties set' -Class Information
        Update-Log -Data 'ConfigMgr feature enabled' -Class Information
        $sitecodetext = 'Site Code - ' + $WPFCMTBSitecode.text
        Update-Log -Data $sitecodetext -Class Information
        $siteservertext = 'Site Server - ' + $WPFCMTBSiteServer.text
        Update-Log -Data $siteservertext -Class Information

        $CMConfig = @{
            SiteCode   = $WPFCMTBSitecode.text
            SiteServer = $WPFCMTBSiteServer.text
        }
        Update-Log -data 'Saving ConfigMgr site information...'
        $CMConfig | Export-Clixml -Path $PSScriptRoot\ConfigMgr\SiteInfo.xml -ErrorAction Stop

        if ($CM -eq 'New') {
            $WPFCMCBImageType.SelectedIndex = 1
            Enable-ConfigMgrOptions
        }

        return 0
    }

    catch {
        Update-Log -Data 'ConfigMgr not detected' -Class Information
        $WPFCMTBSiteServer.text = 'Not Detected'
        $WPFCMTBSitecode.text = 'Not Detected'
        return 1
    }


}

#Function to detect and import CM PowerShell module
Function Import-CMModule() {
    try {
        $path = (($env:SMS_ADMIN_UI_PATH -replace 'i386', '') + 'ConfigurationManager.psd1')

        #           $path = "C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\ConfigurationManager.psd1"
        Import-Module $path -ErrorAction Stop
        Update-Log -Data 'ConfigMgr PowerShell module imported' -Class Information
        return 0
    }

    catch {
        Update-Log -Data 'Could not import CM PowerShell module.' -Class Warning
        return 1
    }
}

#Function to apply the start menu layout
Function Install-StartLayout {
    try {
        $startpath = $WPFMISMountTextBox.Text + '\users\default\appdata\local\microsoft\windows\shell'
        Update-Log -Data 'Copying the start menu file...' -Class Information
        Copy-Item $WPFCustomTBStartMenu.Text -Destination $startpath -ErrorAction Stop
        $filename = (Split-Path -Path $WPFCustomTBStartMenu.Text -Leaf)

        $OS = $Windowstype

        if ($os -eq 'Windows 11') {
            if ($filename -ne 'LayoutModification.json') {
                $newpath = $startpath + '\' + $filename
                Update-Log -Data 'Renaming json file...' -Class Warning
                Rename-Item -Path $newpath -NewName 'LayoutModification.json'
                Update-Log -Data 'file renamed to LayoutModification.json' -Class Information
            }
        }

        if ($os -ne 'Windows 11') {
            if ($filename -ne 'LayoutModification.xml') {
                $newpath = $startpath + '\' + $filename
                Update-Log -Data 'Renaming xml file...' -Class Warning
                Rename-Item -Path $newpath -NewName 'LayoutModification.xml'
                Update-Log -Data 'file renamed to LayoutModification.xml' -Class Information
            }
        }



    }
    catch {
        Update-Log -Data "Couldn't apply the start menu XML" -Class Error
        Update-Log -data $_.Exception.Message -Class Error
    }
}

#Function to apply the default application association
Function Install-DefaultApplicationAssociations {
    try {
        Update-Log -Data 'Applying Default Application Association XML...'
        "Dism.exe /image:$WPFMISMountTextBox.text /Import-DefaultAppAssociations:$WPFCustomTBDefaultApp.text"
        Update-log -data 'Default Application Association applied' -Class Information

    }
    catch {
        Update-Log -Data 'Could not apply Default Appklication Association XML...' -Class Error
        Update-Log -data $_.Exception.Message -Class Error
    }
}

#Function to select default app association xml
Function Select-DefaultApplicationAssociations {

    $Sourcexml = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter           = 'XML (*.xml)|'
    }
    $null = $Sourcexml.ShowDialog()
    $WPFCustomTBDefaultApp.text = $Sourcexml.FileName


    if ($Sourcexml.FileName -notlike '*.xml') {
        Update-Log -Data 'A XML file not selected. Please select a valid file to continue.' -Class Warning
        return
    }
    $text = $WPFCustomTBDefaultApp.text + ' selected as the default application XML'
    Update-Log -Data $text -class Information
}

#Function to select start menu xml
Function Select-StartMenu {

    $OS = Get-WindowsType

    if ($OS -ne 'Windows 11') {
        $Sourcexml = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath('Desktop')
            Filter           = 'XML (*.xml)|'
        }
    }

    if ($OS -eq 'Windows 11') {
        $Sourcexml = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath('Desktop')
            Filter           = 'JSON (*.JSON)|'
        }
    }

    $null = $Sourcexml.ShowDialog()
    $WPFCustomTBStartMenu.text = $Sourcexml.FileName

    if ($OS -ne 'Windows 11') {
        if ($Sourcexml.FileName -notlike '*.xml') {
            Update-Log -Data 'A XML file not selected. Please select a valid file to continue.' -Class Warning
            return
        }
    }

    if ($OS -eq 'Windows 11') {
        if ($Sourcexml.FileName -notlike '*.json') {
            Update-Log -Data 'A JSON file not selected. Please select a valid file to continue.' -Class Warning
            return
        }
    }




    $text = $WPFCustomTBStartMenu.text + ' selected as the start menu file'
    Update-Log -Data $text -class Information
}

#Function to select registry files
Function Select-RegFiles {

    $Regfiles = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Multiselect      = $true # Multiple files can be chosen
        Filter           = 'REG (*.reg)|'
    }
    $null = $Regfiles.ShowDialog()

    $filepaths = $regfiles.FileNames
    Update-Log -data 'Importing REG files...' -class information
    foreach ($filepath in $filepaths) {
        if ($filepath -notlike '*.reg') {
            Update-Log -Data $filepath -Class Warning
            Update-Log -Data 'Ignoring this file as it is not a .REG file....' -Class Warning
            return
        }
        Update-Log -Data $filepath -Class Information
        $WPFCustomLBRegistry.Items.Add($filepath)
    }
    Update-Log -data 'REG file importation complete' -class information

    #Fix this shit, then you can release her.
}

#Function to apply registry files to mounted image
Function Install-RegistryFiles {

    #mount offline hives
    Update-Log -Data 'Mounting the offline registry hives...' -Class Information

    try {
        $Path = $WPFMISMountTextBox.text + '\Users\Default\NTUser.dat'
        Update-Log -Data $path -Class Information
        Invoke-Command { reg load HKLM\OfflineDefaultUser $Path } -ErrorAction Stop | Out-Null

        $Path = $WPFMISMountTextBox.text + '\Windows\System32\Config\DEFAULT'
        Update-Log -Data $path -Class Information
        Invoke-Command { reg load HKLM\OfflineDefault $Path } -ErrorAction Stop | Out-Null

        $Path = $WPFMISMountTextBox.text + '\Windows\System32\Config\SOFTWARE'
        Update-Log -Data $path -Class Information
        Invoke-Command { reg load HKLM\OfflineSoftware $Path } -ErrorAction Stop | Out-Null

        $Path = $WPFMISMountTextBox.text + '\Windows\System32\Config\SYSTEM'
        Update-Log -Data $path -Class Information
        Invoke-Command { reg load HKLM\OfflineSystem $Path } -ErrorAction Stop | Out-Null
    }
    catch {
        Update-Log -Data "Failed to mount $Path" -Class Error
        Update-Log -data $_.Exception.Message -Class Error
    }

    #get reg files from list box
    $RegFiles = $WPFCustomLBRegistry.items

    #For Each to process Reg Files and Apply
    Update-Log -Data 'Processing Reg Files...' -Class Information
    foreach ($RegFile in $Regfiles) {

        Update-Log -Data $RegFile -Class Information
        #write-host $RegFile

        Try {
            $Destination = $PSScriptRoot + '\staging\'
            Update-Log -Data 'Copying file to staging folder...' -Class Information
            Copy-Item -Path $regfile -Destination $Destination -Force -ErrorAction Stop  #Copy Source Registry File to staging
        }
        Catch {
            Update-Log -Data "Couldn't copy reg file" -Class Error
            Update-Log -data $_.Exception.Message -Class Error
        }

        $regtemp = Split-Path $regfile -Leaf #get file name
        $regpath = $PSScriptRoot + '\staging' + '\' + $regtemp

        # Write-Host $regpath
        Try {
            Update-Log -Data 'Parsing reg file...'
           ((Get-Content -Path $regpath -Raw) -replace 'HKEY_CURRENT_USER', 'HKEY_LOCAL_MACHINE\OfflineDefaultUser') | Set-Content -Path $regpath -ErrorAction Stop
           ((Get-Content -Path $regpath -Raw) -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE', 'HKEY_LOCAL_MACHINE\OfflineSoftware') | Set-Content -Path $regpath -ErrorAction Stop
           ((Get-Content -Path $regpath -Raw) -replace 'HKEY_LOCAL_MACHINE\\SYSTEM', 'HKEY_LOCAL_MACHINE\OfflineSystem') | Set-Content -Path $regpath -ErrorAction Stop
           ((Get-Content -Path $regpath -Raw) -replace 'HKEY_USERS\\.DEFAULT', 'HKEY_LOCAL_MACHINE\OfflineDefault') | Set-Content -Path $regpath -ErrorAction Stop
        }
        Catch {
            Update-log -Data "Couldn't read or update reg file $regpath" -Class Error
            Update-Log -data $_.Exception.Message -Class Error
        }

        Update-Log -Data 'Reg file has been parsed' -Class Information

        #import the registry file

        Try {
            Update-Log -Data 'Importing registry file into mounted wim' -Class Information
            Start-Process reg -ArgumentList ('import', "`"$RegPath`"") -Wait -WindowStyle Hidden -ErrorAction stop
            Update-Log -Data 'Import successful' -Class Information
        }
        Catch {
            Update-Log -Data "Couldn't import $Regpath" -Class Error
            Update-Log -data $_.Exception.Message -Class Error

        }
    }


    #dismount offline hives
    try {
        Update-Log -Data 'Dismounting registry...' -Class Information
        Invoke-Command { reg unload HKLM\OfflineDefaultUser } -ErrorAction Stop | Out-Null
        Invoke-Command { reg unload HKLM\OfflineDefault } -ErrorAction Stop | Out-Null
        Invoke-Command { reg unload HKLM\OfflineSoftware } -ErrorAction Stop | Out-Null
        Invoke-Command { reg unload HKLM\OfflineSystem } -ErrorAction Stop | Out-Null
        Update-Log -Data 'Dismount complete' -Class Information
    }
    catch {
        Update-Log -Data "Couldn't dismount the registry hives" -Class Error
        Update-Log -Data 'This will prevent the Windows image from properly dismounting' -Class Error
        Update-Log -data $_.Exception.Message -Class Error

    }

}

#Function to augment close out window text
Function Invoke-DadJoke {
    $header = @{accept = 'Application/json' }
    $joke = Invoke-RestMethod -Uri 'https://icanhazdadjoke.com' -Method Get -Headers $header
    return $joke.joke
}

#Function to stage and build installer media
Function Copy-StageIsoMedia {
    # if($WPFSourceWIMImgDesTextBox.Text -like '*Windows 10*'){$OS = 'Windows 10'}
    # if($WPFSourceWIMImgDesTextBox.Text -like '*Server*'){$OS = 'Windows Server'}

    $OS = Get-WindowsType


    #$Ver = (Get-WinVersionNumber)
    $Ver = $MISWinVer


    #create staging folder
    try {
        Update-Log -Data 'Creating staging folder for media' -Class Information
        New-Item -Path $PSScriptRoot\staging -Name 'Media' -ItemType Directory -ErrorAction Stop | Out-Null
        Update-Log -Data 'Media staging folder has been created' -Class Information
    }
    catch {
        Update-Log -Data 'Could not create staging folder' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

    #copy source to staging
    try {
        Update-Log -data 'Staging media binaries...' -Class Information
        Copy-Item -Path $PSScriptRoot\imports\iso\$OS\$Ver\* -Destination $PSScriptRoot\staging\media -Force -Recurse -ErrorAction Stop
        Update-Log -data 'Media files have been staged' -Class Information
    }
    catch {
        Update-Log -Data 'Failed to stage media binaries...' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

}

#Function to create the ISO file from staged installer media
Function New-WindowsISO {

    if ((Test-Path -Path ${env:ProgramFiles(x86)}'\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe' -PathType Leaf) -eq $false) {
        Update-Log -Data 'The file oscdimg.exe was not found. Skipping ISO creation...' -Class Error
        return
    }

    If ($WPFMISTBISOFileName.Text -notlike '*.iso') {

        $WPFMISTBISOFileName.Text = $WPFMISTBISOFileName.Text + '.iso'
        Update-Log -Data 'Appending new file name with an extension' -Class Information
    }

    $Location = ${env:ProgramFiles(x86)}
    $executable = $location + '\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
    $bootbin = $PSScriptRoot + '\staging\media\efi\microsoft\boot\efisys.bin'
    $source = $PSScriptRoot + '\staging\media'
    $folder = $WPFMISTBFilePath.text
    $file = $WPFMISTBISOFileName.text
    $dest = "$folder\$file"
    $text = "-b$bootbin"

    if ((Test-Path -Path $dest) -eq $true) { Rename-Name -file $dest -extension '.iso' }
    try {
        Update-Log -Data 'Starting to build ISO...' -Class Information
        # write-host $executable
        Start-Process $executable -args @("`"$text`"", '-pEF', '-u1', '-udfver102', "`"$source`"", "`"$dest`"") -Wait -ErrorAction Stop
        Update-Log -Data 'ISO has been built' -Class Information
    }
    catch {
        Update-Log -Data "Couldn't create the ISO file" -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }
}

#Function to copy staged installer media to CM Package Share
Function Copy-UpgradePackage {
    #copy staging folder to destination with force parameter
    try {
        Update-Log -data 'Copying updated media to Upgrade Package folder...' -Class Information
        Copy-Item -Path $PSScriptRoot\staging\media\* -Destination $WPFMISTBUpgradePackage.text -Force -Recurse -ErrorAction Stop
        Update-Log -Data 'Updated media has been copied' -Class Information
    }
    catch {
        Update-Log -Data "Couldn't copy the updated media to the upgrade package folder" -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }

}

#Function to update the boot wim in the staged installer media folder
Function Update-BootWIM {
    #create mount point in staging

    try {
        Update-Log -Data 'Creating mount point in staging folder...'
        New-Item -Path $PSScriptRoot\staging -Name 'mount' -ItemType Directory -ErrorAction Stop
        Update-Log -Data 'Staging folder mount point created successfully' -Class Information
    }
    catch {
        Update-Log -data 'Failed to create the staging folder mount point' -Class Error
        Update-Log -data $_.Exception.Message -class Error
        return
    }


    #change attribute of boot.wim
    #Change file attribute to normal
    Update-Log -Data 'Setting file attribute of boot.wim to Normal' -Class Information
    $attrib = Get-Item $PSScriptRoot\staging\media\sources\boot.wim
    $attrib.Attributes = 'Normal'

    $BootImages = Get-WindowsImage -ImagePath $PSScriptRoot\staging\media\sources\boot.wim
    Foreach ($BootImage in $BootImages) {

        #Mount the PE Image
        try {
            $text = 'Mounting PE image number ' + $BootImage.ImageIndex
            Update-Log -data $text -Class Information
            Mount-WindowsImage -ImagePath $PSScriptRoot\staging\media\sources\boot.wim -Path $PSScriptRoot\staging\mount -Index $BootImage.ImageIndex -ErrorAction Stop
        }
        catch {
            Update-Log -Data 'Could not mount the boot.wim' -Class Error
            Update-Log -data $_.Exception.Message -class Error
            return
        }

        Update-Log -data 'Applying SSU Update' -Class Information
        Deploy-Updates -class 'PESSU'
        Update-Log -data 'Applying LCU Update' -Class Information
        Deploy-Updates -class 'PELCU'

        #Dismount the PE Image
        try {
            Update-Log -data 'Dismounting Windows PE image...' -Class Information
            Dismount-WindowsImage -Path $PSScriptRoot\staging\mount -Save -ErrorAction Stop
        }
        catch {
            Update-Log -data 'Could not dismount the winpe image.' -Class Error
            Update-Log -data $_.Exception.Message -class Error
        }

        #Export the WinPE Image
        Try {
            Update-Log -data 'Exporting WinPE image index...' -Class Information
            Export-WindowsImage -SourceImagePath $PSScriptRoot\staging\media\sources\boot.wim -SourceIndex $BootImage.ImageIndex -DestinationImagePath $PSScriptRoot\staging\tempboot.wim -ErrorAction Stop
        }
        catch {
            Update-Log -Data 'Failed to export WinPE image' -Class Error
            Update-Log -data $_.Exception.Message -class Error
        }

    }

    #Overwrite the stock boot.wim file with the updated one
    try {
        Update-Log -Data 'Overwriting boot.wim with updated and optimized version...' -Class Information
        Move-Item -Path $PSScriptRoot\staging\tempboot.wim -Destination $PSScriptRoot\staging\media\sources\boot.wim -Force -ErrorAction Stop
        Update-Log -Data 'Boot.WIM updated successfully' -Class Information
    }
    catch {
        Update-Log -Data 'Could not copy the updated boot.wim' -Class Error
        Update-Log -data $_.Exception.Message -class Error
    }
}

#Function to update windows recovery in the mounted offline image
Function Update-WinReWim {
    #create mount point in staging
    #copy winre from mounted offline image
    #change attribute of winre.wim
    #mount staged winre.wim
    #update, dismount
    #copy wim back to mounted offline image
}

#Function to retrieve windows version
Function Get-WinVersionNumber {
    If ($WPFSourceWimVerTextBox.text -like '10.0.14393.*') { $buildnum = 1607 }
    If ($WPFSourceWimVerTextBox.text -like '10.0.17763.*') { $buildnum = 1809 }
    If ($WPFSourceWimVerTextBox.text -like '10.0.17134.*') { $buildnum = 1803 }
    If ($WPFSourceWimVerTextBox.text -like '10.0.16299.*') { $buildnum = 1709 }
    If ($WPFSourceWimVerTextBox.text -like '10.0.22000.*') { $buildnum = '21H2' }
    If ($WPFSourceWimVerTextBox.text -like '10.0.20348.*') { $buildnum = '21H2' }
    If ($WPFSourceWimVerTextBox.text -like '10.0.18362.*') { $buildnum = 1909 }
    If ($WPFSourceWimVerTextBox.text -like '10.0.19042.*') { $buildnum = '20H2' }
    If ($WPFSourceWimVerTextBox.text -like '10.0.19043.*') { $buildnum = '21H1' }
    If ($WPFSourceWimVerTextBox.text -like '10.0.19044.*') { $buildnum = '21H2' }
    If ($WPFSourceWimVerTextBox.text -like '10.0.22621.*') { $buildnum = '22H2' }

    If ($WPFSourceWimVerTextBox.text -like '10.0.19041.*') {
        $IsMountPoint = $False
        $currentmounts = Get-WindowsImage -Mounted
        foreach ($currentmount in $currentmounts) {
            if ($currentmount.path -eq $WPFMISMountTextBox.text) { $IsMountPoint = $true }
        }

        #IS a mount path
        If ($IsMountPoint -eq $true) {
            $mountdir = $WPFMISMountTextBox.Text
            reg LOAD HKLM\OFFLINE $mountdir\Windows\System32\Config\SOFTWARE | Out-Null
            $regvalues = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\OFFLINE\Microsoft\Windows NT\CurrentVersion\' )
            $buildnum = $regvalues.ReleaseId
            if ($regvalues.ReleaseId -eq '2009') {
                if ($regvalues.CurrentBuild -eq '19042') { $buildnum = '2009' }
                if ($regvalues.CurrentBuild -eq '19043') { $buildnum = '21H1' }
                if ($regvalues.CurrentBuild -eq '19044') { $buildnum = '21H2' }
                if ($regvalues.CurrentBuild -eq '19045') { $buildnum = '22H2' }
            }

            reg UNLOAD HKLM\OFFLINE | Out-Null


        }

        If ($IsMountPoint -eq $False) {
            $global:Win10VerDet = $null

            #$global:Win10VerDet = ""


            Update-Log -data 'Prompting user for Win10 version confirmation...' -class Information

            Invoke-19041Select

            if ($null -eq $global:Win10VerDet) { return }

            $temp = $global:Win10VerDet

            $buildnum = $temp
            Update-Log -data "User selected $buildnum" -class Information

            $global:Win10VerDet = $null

        }
    }

    return $buildnum
}

#funcation to select ISO creation path
Function Select-ISODirectory {

    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = 'Select the folder to save the ISO'
    $null = $browser.ShowDialog()
    $MountDir = $browser.SelectedPath
    $WPFMISTBFilePath.text = $MountDir
    #Test-MountPath -path $WPFMISMountTextBox.text
    Update-Log -Data 'ISO directory selected' -Class Information
}

#Function to determine if WIM is Win10 or Windows Server
Function Get-WindowsType {
    if ($WPFSourceWIMImgDesTextBox.text -like '*Windows 10*') { $type = 'Windows 10' }
    if ($WPFSourceWIMImgDesTextBox.text -like '*Windows Server*') { $type = 'Windows Server' }
    if ($WPFSourceWIMImgDesTextBox.text -like '*Windows 11*') { $type = 'Windows 11' }

    Return $type
}

#Function to check if ISO binaries exist
Function Test-IsoBinariesExist {
    $buildnum = Get-WinVersionNumber
    $OSType = get-Windowstype


    $ISOFiles = $PSScriptRoot + '\imports\iso\' + $OSType + '\' + $buildnum + '\'

    Test-Path -Path $ISOFiles\*
    if ((Test-Path -Path $ISOFiles\*) -eq $false) {
        $text = 'ISO Binaries are not present for ' + $OSType + ' ' + $buildnum
        Update-Log -Data $text -Class Warning
        Update-Log -data 'Import ISO Binaries from an ISO or disable ISO/Upgrade Package creation' -Class Warning
        return $false
    }
}

#Function to clear partial checkboxes when importing config file
Function Invoke-CheckboxCleanup {
    Update-Log -Data 'Cleaning null checkboxes...' -Class Information
    $Variables = Get-Variable WPF*
    foreach ($variable in $variables) {

        if ($variable.value -like '*.CheckBox*') {
            #write-host $variable.name
            #write-host $variable.value.IsChecked
            if ($variable.value.IsChecked -ne $true) { $variable.value.IsChecked = $false }
        }
    }
}

#Function to really make sure the ISO mount is gone!
Function Invoke-RemoveISOMount ($inputObject) {
    DO {
        Dismount-DiskImage -InputObject $inputObject
    }
    while (Dismount-DiskImage -InputObject $inputObject)
    #He's dead Jim!
    Update-Log -data 'Dismount complete' -class Information
}

#Function to check for available free space
Function Test-FreeSpace {

    $Drive = $PSScriptRoot.Substring(0, 2)

    $DriveInfo = (Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '$Drive'")

    if ($driveinfo.freespace -lt 20000000000) { return 1 }
    Else
    { return 0 }
}

#Function to install CM Console extensions
Function Install-WWCMConsoleExtension {
    $UpdateWWXML = @"
<ActionDescription Class ="Executable" DisplayName="Update with WIM Witch" MnemonicDisplayName="Update with WIM Witch" Description="Click to update the image with WIM Witch">
	<ShowOn>
		<string>ContextMenu</string>
		<string>DefaultHomeTab</string>
	</ShowOn>
	<Executable>
		<FilePath>$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe</FilePath>
		<Parameters> -ExecutionPolicy Bypass -File "$PSCommandPath" -auto -autofile "$PSScriptRoot\ConfigMgr\PackageInfo\##SUB:PackageID##"</Parameters>
	</Executable>
</ActionDescription>
"@

    $EditWWXML = @"
<ActionDescription Class ="Executable" DisplayName="Edit WIM Witch Image Config" MnemonicDisplayName="Edit WIM Witch Image Config" Description="Click to edit the WIM Witch image configuration">
	<ShowOn>
		<string>ContextMenu</string>
		<string>DefaultHomeTab</string>
	</ShowOn>
	<Executable>
		<FilePath>$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe</FilePath>
		<Parameters> -ExecutionPolicy Bypass -File "$PSCommandPath" -CM "Edit" -autofile "$PSScriptRoot\ConfigMgr\PackageInfo\##SUB:PackageID##"</Parameters>
	</Executable>
</ActionDescription>
"@

    $NewWWXML = @"
<ActionDescription Class ="Executable" DisplayName="New WIM Witch Image" MnemonicDisplayName="New WIM Witch Image" Description="Click to create a new WIM Witch image">
	<ShowOn>
		<string>ContextMenu</string>
		<string>DefaultHomeTab</string>
	</ShowOn>
	<Executable>
		<FilePath>$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe</FilePath>
		<Parameters> -ExecutionPolicy Bypass -File "$PSCommandPath" -CM "New"</Parameters>
	</Executable>
</ActionDescription>
"@

    Update-Log -Data 'Installing ConfigMgr console extension...' -Class Information

    $ConsoleFolderImage = '828a154e-4c7d-4d7f-ba6c-268443cdb4e8' #folder for update and edit

    $ConsoleFolderRoot = 'ac16f420-2d72-4056-a8f6-aef90e66a10c' #folder for new

    $path = ($env:SMS_ADMIN_UI_PATH -replace 'bin\\i386', '') + 'XmlStorage\Extensions\Actions'

    Update-Log -Data 'Creating folders if needed...' -Class Information

    if ((Test-Path -Path (Join-Path -Path $path -ChildPath $ConsoleFolderImage)) -eq $false) { New-Item -Path $path -Name $ConsoleFolderImage -ItemType 'directory' | Out-Null }

    Update-Log -data 'Creating extension files...' -Class Information

    $UpdateWWXML | Out-File ((Join-Path -Path $path -ChildPath $ConsoleFolderImage) + '\UpdateWWImage.xml') -Force
    $EditWWXML | Out-File ((Join-Path -Path $path -ChildPath $ConsoleFolderImage) + '\EditWWImage.xml') -Force

    Update-Log -Data 'Creating folders if needed...' -Class Information

    if ((Test-Path -Path (Join-Path -Path $path -ChildPath $ConsoleFolderRoot)) -eq $false) { New-Item -Path $path -Name $ConsoleFolderRoot -ItemType 'directory' | Out-Null }
    Update-Log -data 'Creating extension files...' -Class Information

    $NewWWXML | Out-File ((Join-Path -Path $path -ChildPath $ConsoleFolderRoot) + '\NewWWImage.xml') -Force

    Update-Log -Data 'Console extension installation complete!' -Class Information
}

#Function to handle 32-Bit PowerSehell
Function Invoke-ArchitectureCheck {
    if ([Environment]::Is64BitProcess -ne [Environment]::Is64BitOperatingSystem) {

        Update-Log -Data 'This is 32-bit PowerShell session. Will relaunch as 64-bit...' -Class Warning

        #The following If statment was pilfered from Michael Niehaus
        if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {

            if (($auto -eq $false) -and ($CM -eq 'None')) { & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" }
            if (($auto -eq $true) -and ($null -ne $autofile)) { & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -auto -autofile $autofile }
            if (($CM -eq 'Edit') -and ($null -ne $autofile)) { & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -CM Edit -autofile $autofile }
            if ($CM -eq 'New') { & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -CM New }

            Exit $lastexitcode
        }


        ###end here


    }

    else {
        Update-Log -Data 'This is a 64 bit PowerShell session' -Class Information


    }
}

#Function to handle admin rights escalation
Function Invoke-AdminCheck {
    $editscript = @"
Start-Process powershell -ArgumentList '-noprofile -file "$PSCommandPath" -CM Edit -autofile "$autofile"' -verb RunAs
"@

    $UpdateScript = @"
Start-Process powershell -ArgumentList '-noprofile -File "$PSCommandPath" -auto -autofile "$autofile"' -verb RunAs
"@

    $NewScript = @"
Start-Process powershell -ArgumentList '-noprofile -file "$PSCommandPath" -CM "New"' -verb RunAs
"@

    $LaunchScript = @"
Start-Process powershell -ArgumentList '-noprofile -file "$PSCommandPath"' -verb RunAs
"@

    if ((Test-Path $PSScriptRoot\temp) -eq $false) { New-Item -Path $PSScriptRoot -Name 'Temp' -ItemType Directory }


    If ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544') -ne $true) {

        Update-Log -Data 'This session is not running as admin. Will relaunch as admin...' -Class Warning


        if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {





            #   if (($auto -eq $false) -and ($CM -eq "None")){& "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"}
            if (($auto -eq $false) -and ($CM -eq 'None')) {
                $launchscript | Out-File $PSScriptRoot\temp\launch.ps1
                & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSScriptRoot\temp\launch.ps1"
            }

            #if (($auto -eq $true) -and ($autofile -ne $null)){& "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -auto -autofile $autofile}
            if (($auto -eq $true) -and ($null -ne $autofile)) {
                $updatescript | Out-File $PSScriptRoot\temp\launch.ps1
                & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSScriptRoot\temp\launch.ps1"
            }

            #if (($CM -eq "Edit") -and ($autofile -ne $null)){& "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -CM Edit -autofile $autofile}
            if (($CM -eq 'Edit') -and ($null -ne $autofile)) {
                $editscript | Out-File $PSScriptRoot\temp\launch.ps1
                & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSScriptRoot\temp\launch.ps1"
            }


            #if ($CM -eq "New"){& "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath" -CM New}
            if ($CM -eq 'New') {
                $NewScript | Out-File $PSScriptRoot\temp\launch.ps1
                & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSScriptRoot\temp\launch.ps1"
            }

            Exit $lastexitcode
        }


        ###end here


    }

    else {
        Update-Log -Data 'This session is running as admin' -Class Information


    }


}

#Function to download and extract the SSU required for 2004/20H2 June '21 LCU
Function Invoke-2XXXPreReq {
    $KB_URI = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/05/windows10.0-kb5003173-x64_375062f9d88a5d9d11c5b99673792fdce8079e09.cab'
    $executable = "$env:windir\system32\expand.exe"
    $mountdir = $WPFMISMountTextBox.Text

    Update-Log -data 'Mounting offline registry and validating UBR / Patch level...' -class Information
    reg LOAD HKLM\OFFLINE $mountdir\Windows\System32\Config\SOFTWARE | Out-Null
    $regvalues = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\OFFLINE\Microsoft\Windows NT\CurrentVersion\' )


    Update-Log -data 'The UBR (Patch Level) is:' -class Information
    Update-Log -data $regvalues.ubr -class information
    reg UNLOAD HKLM\OFFLINE | Out-Null

    if ($null -eq $regvalues.ubr) {
        Update-Log -data "Registry key wasn't copied. Can't continue." -class Error
        return 1
    }

    if ($regvalues.UBR -lt '985') {

        Update-Log -data 'The image requires an additional required SSU.' -class Information
        Update-Log -data 'Checking to see if the required SSU exists...' -class Information
        if ((Test-Path "$PSScriptRoot\updates\Windows 10\2XXX_prereq\SSU-19041.985-x64.cab") -eq $false) {
            Update-Log -data 'The required SSU does not exist. Downloading it now...' -class Information

            try {
                Invoke-WebRequest -Uri $KB_URI -OutFile "$PSScriptRoot\staging\extract_me.cab" -ErrorAction stop
            }
            catch {
                Update-Log -data 'Failed to download the update' -class Error
                Update-Log -data $_.Exception.Message -Class Error
                return 1
            }

            if ((Test-Path "$PSScriptRoot\updates\Windows 10\2XXX_prereq") -eq $false) {


                try {
                    Update-Log -data 'The folder for the required SSU does not exist. Creating it now...' -class Information
                    New-Item -Path "$PSScriptRoot\updates\Windows 10" -Name '2XXX_prereq' -ItemType Directory -ErrorAction stop | Out-Null
                    Update-Log -data 'The folder has been created' -class information
                }
                catch {
                    Update-Log -data 'Could not create the required folder.' -class error
                    Update-Log -data $_.Exception.Message -Class Error
                    return 1
                }
            }

            try {
                Update-Log -data 'Extracting the SSU from the May 2021 LCU...' -class Information
                Start-Process $executable -args @("`"$PSScriptRoot\staging\extract_me.cab`"", '/f:*SSU*.CAB', "`"$PSScriptRoot\updates\Windows 10\2XXX_prereq`"") -Wait -ErrorAction Stop
                Update-Log 'Extraction of SSU was success' -class information
            }
            catch {
                Update-Log -data "Couldn't extract the SSU from the LCU" -class error
                Update-Log -data $_.Exception.Message -Class Error
                return 1

            }


            try {
                Update-Log -data 'Deleting the staged LCU file...' -class Information
                Remove-Item -Path $PSScriptRoot\staging\extract_me.cab -Force -ErrorAction stop | Out-Null
                Update-Log -data 'The source file for the SSU has been Baleeted!' -Class Information
            }
            catch {
                Update-Log -data 'Could not delete the source package' -Class Error
                Update-Log -data $_.Exception.Message -Class Error
                return 1
            }
        }
        else {
            Update-Log -data 'The required SSU exists. No need to download' -Class Information
        }

        try {
            Update-Log -data 'Applying the SSU...' -class Information
            Add-WindowsPackage -PackagePath "$PSScriptRoot\updates\Windows 10\2XXX_prereq" -Path $WPFMISMountTextBox.Text -ErrorAction Stop | Out-Null
            Update-Log -data 'SSU applied successfully' -class Information

        }
        catch {
            Update-Log -data "Couldn't apply the SSU update" -class error
            Update-Log -data $_.Exception.Message -Class Error
            return 1
        }
    }
    else {
        Update-Log -Data "Image doesn't require the prereq SSU" -Class Information
    }

    Update-Log -data 'SSU remdiation complete' -Class Information
    return 0
}

#Function to display text notification to end user
Function Invoke-TextNotification {
    Update-Log -data '*********************************' -class Comment
    Update-Log -data 'This version brings: ' -class Comment
    Update-Log -data ' ' -class Comment
    Update-Log -data 'Support for Windows 10 22H2' -Class Comment
    Update-Log -data 'Bugfix for Win10 22H2 update selection' -Class Comment
    Update-Log -data 'Bugfix for Win10 22H2 LP/LXP/FOD selection' -Class comment
    Update-Log -data 'Fix for Win10 22H2 updates downloading with ConfigMgr' -Class Comment
    Update-Log -data ' ' -Class Comment
    Update-Log -data 'If you are servicing Win11 22H2, please validate the' -Class Comment
    Update-Log -data 'Functionality of OneDrive post imaging. This is a new' -Class Comment
    Update-Log -data "method from Microsoft and I haven't tested it much" -Class Comment
    Update-Log -data '*********************************' -class Comment

}

#Function to display Windows 10 v2XXX selection pop up
Function Invoke-19041Select {
    $inputXML = @'
<Window x:Class="popup.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:popup"
        mc:Ignorable="d"
        Title="Select Win10 Version" Height="170" Width="353">
    <Grid x:Name="Win10PU" Margin="0,0,10,6">
        <ComboBox x:Name="Win10PUCombo" HorizontalAlignment="Left" Margin="40,76,0,0" VerticalAlignment="Top" Width="120"/>
        <Button x:Name="Win10PUOK" Content="OK" HorizontalAlignment="Left" Margin="182,76,0,0" VerticalAlignment="Top" Width="50"/>
        <Button x:Name="Win10PUCancel" Content="Cancel" HorizontalAlignment="Left" Margin="248,76,0,0" VerticalAlignment="Top" Width="50"/>
        <TextBlock x:Name="Win10PUText" HorizontalAlignment="Left" Margin="24,27,0,0" Text="Please selet the correct version of Windows 10." TextWrapping="Wrap" VerticalAlignment="Top" Grid.ColumnSpan="2"/>

    </Grid>
</Window>

'@

    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace 'x:N', 'N' -replace '^<Win.*', '<Window'
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $inputXML
    #Read XAML

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $Form = [Windows.Markup.XamlReader]::Load( $reader )
    }
    catch {
        Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
        throw
    }

    $xaml.SelectNodes('//*[@Name]') | ForEach-Object { "trying item $($_.Name)" | Out-Null
        try { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
        catch { throw }
    }

    Function Get-FormVariables {
        if ($global:ReadmeDisplay -ne $true) {
            #Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true
        }
        #write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
        Get-Variable WPF*
    }

    Get-FormVariables | Out-Null

    #Combo Box population
    $Win10VerNums = @('20H2', '21H1', '21H2', '22H2')
    Foreach ($Win10VerNum in $Win10VerNums) { $WPFWin10PUCombo.Items.Add($Win10VerNum) | Out-Null }


    #Button_OK_Click
    $WPFWin10PUOK.Add_Click({
            $global:Win10VerDet = $WPFWin10PUCombo.SelectedItem
            $Form.Close()
            return
        })

    #Button_Cancel_Click
    $WPFWin10PUCancel.Add_Click({
            $global:Win10VerDet = $null
            Update-Log -data 'User cancelled the confirmation dialog box' -Class Warning
            $Form.Close()
            return
        })


    $Form.ShowDialog() | Out-Null

}
#endregion Functions

#region Main
#===========================================================================
# Run commands to set values of files and variables, etc.
#===========================================================================

#calls fuction to display the opening text blurb


Show-OpeningText
#Get-FormVariables #lists all WPF variables
Test-Install
#Set the path and name for logging
$Log = "$PSScriptRoot\logging\WIMWitch.log"

Set-Logging #Clears out old logs from previous builds and checks for other folders

##################
# Prereq Check segment

#Check for installed PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 5) { Update-Log -Data 'PowerShell v5 or greater installed.' -Class Information }
else {
    Update-Log -data 'PowerShell v5 or greater is required. Please upgrade PowerShell and try again.' -Class Error
    Show-ClosingText
    exit 0
}


#Check for available space
if ($SkipFreeSpaceCheck -eq $false) {

    if (Test-FreeSpace -eq 1) {
        Update-Log -Data 'Insufficient free space. Please clean up disk and try again' -Class Error
        Update-Log -Data 'If you would like to bypass the free space check, please run' -Class Error
        Update-Log -data 'with the parameter -SkipFreeSpaceCheck' -Class Error
        Update-Log -data 'Example: .\WimWitch.ps1 -SkipFreeSpaceCheck' -Class Error
        Show-ClosingText
        exit 0
    }
    Else
    { Update-Log -Data 'Plenty of HDD space available!' -class Information }
}

#Check for admin rights
Invoke-AdminCheck

#Check for 32 bit architecture
Invoke-ArchitectureCheck

#End Prereq segment
###################


#===========================================================================
Test-WIMWitchVer #Checks installed version of WIM Witch and updates if selected

#This randon line was inserted on 7/3/2020.

#===========================================================================

#===========================================================================
# Set default values for certain variables
#===========================================================================

#Set the value of the JSON field in Make It So tab
$WPFMISJSONTextBox.Text = 'False'

#Set the value of the Driver field in the Make It So tab
$WPFMISDriverTextBox.Text = 'False'

#Set the value of the Updates field in the Make It So tab
$WPFMISUpdatesTextBox.Text = 'False'

$WPFMISAppxTextBox.Text = 'False'

$global:Win10VerDet = ''

#===========================================================================
# Section for Combo box Functions
#===========================================================================

#Set the combo box values of the other import tab

$ObjectTypes = @('Language Pack', 'Local Experience Pack', 'Feature On Demand')
$WinOS = @('Windows Server', 'Windows 10', 'Windows 11')
$WinSrvVer = @('2019', '21H2')
$Win10Ver = @('1809', '2004')
$Win11Ver = @('21H2', '22H2')

Foreach ($ObjectType in $ObjectTypes) { $WPFImportOtherCBType.Items.Add($ObjectType) | Out-Null }
Foreach ($WinOS in $WinOS) { $WPFImportOtherCBWinOS.Items.Add($WinOS) | Out-Null }

#Run Script Timing combox box
$RunScriptActions = @('After image mount', 'Before image dismount', 'On build completion')
Foreach ($RunScriptAction in $RunScriptActions) { $WPFCustomCBScriptTiming.Items.add($RunScriptAction) | Out-Null }

#ConfigMgr Tab Combo boxes
$ImageTypeCombos = @('Disabled', 'New Image', 'Update Existing Image')
$DPTypeCombos = @('Distribution Points', 'Distribution Point Groups')
foreach ($ImageTypeCombo in $ImageTypeCombos) { $WPFCMCBImageType.Items.Add($ImageTypeCombo) | Out-Null }
foreach ($DPTypeCombo in $DPTypeCombos) { $WPFCMCBDPDPG.Items.Add($DPTypeCombo) | Out-Null }
$WPFCMCBDPDPG.SelectedIndex = 0
$WPFCMCBImageType.SelectedIndex = 0


Enable-ConfigMgrOptions

#Software Update Catalog Source combo box
$UpdateSourceCombos = @('None', 'OSDSUS', 'ConfigMgr')
foreach ($UpdateSourceCombo in $UpdateSourceCombos) { $WPFUSCBSelectCatalogSource.Items.Add($UpdateSourceCombo) | Out-Null }
$WPFUSCBSelectCatalogSource.SelectedIndex = 0
Invoke-UpdateTabOptions

#Check for ConfigMgr and set integration
if ((Find-ConfigManager) -eq 0) {

    if ((Import-CMModule) -eq 0) {
        $WPFUSCBSelectCatalogSource.SelectedIndex = 2
        Invoke-UpdateTabOptions
    }
}
else
{ Update-Log -Data 'Skipping ConfigMgr PowerShell module importation' }

#Set OSDSUS to Patch Catalog if CM isn't integratedg

if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 0) {
    Update-Log -Data 'Setting OSDSUS as the Update Catalog' -Class Information
    $WPFUSCBSelectCatalogSource.SelectedIndex = 1
    Invoke-UpdateTabOptions
}

#Function Get-WindowsPatches($build,$OS)

if ($DownloadUpdates -eq $true) {
    #    If (($UpdatePoShModules -eq $true) -and ($WPFUpdatesOSDBOutOfDateTextBlock.Visibility -eq "Visible")) {
    If ($UpdatePoShModules -eq $true ) {
        Update-OSDB
        Update-OSDSUS
    }


    if ($Server2016 -eq $true) {
        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
            Test-Superceded -action delete -OS 'Windows Server' -Build 1607
            Get-WindowsPatches -OS 'Windows Server' -build 1607
        }


        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver 1607
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver 1607
        }
    }

    if ($Server2019 -eq $true) {
        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
            Test-Superceded -action delete -OS 'Windows Server' -Build 1809
            Get-WindowsPatches -OS 'Windows Server' -build 1809
        }

        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver 1809
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver 1809
        }
    }

    if ($Server2022 -eq $true) {
        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
            Test-Superceded -action delete -OS 'Windows Server' -Build 21H2
            Get-WindowsPatches -OS 'Windows Server' -build 21H2
        }


        if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
            Invoke-MEMCMUpdateSupersedence -prod 'Windows Server' -Ver 21H2
            Invoke-MEMCMUpdatecatalog -prod 'Windows Server' -Ver 21H2
        }
    }


    if ($Win10Version -ne 'none') {
        if (($Win10Version -eq '1709')) {
            # -or ($Win10Version -eq "all")){
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 1709
                Get-WindowsPatches -OS 'Windows 10' -build 1709
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 1709
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 1709
            }
        }

        if (($Win10Version -eq '1803')) {
            # -or ($Win10Version -eq "all")){
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 1803
                Get-WindowsPatches -OS 'Windows 10' -build 1803
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 1803
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 1803
            }
        }

        if (($Win10Version -eq '1809') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 1809
                Get-WindowsPatches -OS 'Windows 10' -build 1809
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 1809
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 1809
            }
        }


        if (($Win10Version -eq '1903')) {
            # -or ($Win10Version -eq "all")){
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 1903
                Get-WindowsPatches -OS 'Windows 10' -build 1903
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 1903
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 1903
            }
        }


        if (($Win10Version -eq '1909') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 1909
                Get-WindowsPatches -OS 'Windows 10' -build 1909
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 1909
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 1909
            }
        }

        if (($Win10Version -eq '2004') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 2004
                Get-WindowsPatches -OS 'Windows 10' -build 2004
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 2004
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 2004
            }
        }

        if (($Win10Version -eq '20H2') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 2009
                Get-WindowsPatches -OS 'Windows 10' -build 2009
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 2009
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 2009
            }
        }

        if (($Win10Version -eq '21H1') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 21H1
                Get-WindowsPatches -OS 'Windows 10' -build 21H1
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 21H1
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 21H1
            }
        }

        if (($Win10Version -eq '21H2') -or ($Win10Version -eq 'all')) {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 10' -Build 21H2
                Get-WindowsPatches -OS 'Windows 10' -build 21H2
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 10' -Ver 21H2
                Invoke-MEMCMUpdatecatalog -prod 'Windows 10' -Ver 21H2
            }
        }

        if ($Win11Version -eq '21H2') {
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 1) {
                Test-Superceded -action delete -OS 'Windows 11' -Build 21H2
                Get-WindowsPatches -OS 'Windows 11' -build 21H2
            }
            if ($WPFUSCBSelectCatalogSource.SelectedIndex -eq 2) {
                Invoke-MEMCMUpdateSupersedence -prod 'Windows 11' -Ver 21H2
                Invoke-MEMCMUpdatecatalog -prod 'Windows 11' -Ver 21H2
            }
        }


        Get-OneDrive
    }
}

#===========================================================================
# Section for Buttons to call Functions
#===========================================================================

#Mount Dir Button
$WPFMISMountSelectButton.Add_Click( { SelectMountdir })

#Source WIM File Button
$WPFSourceWIMSelectButton.Add_Click( { Select-SourceWIM })

#JSON File selection Button
$WPFJSONButton.Add_Click( { Select-JSONFile })

#Target Folder selection Button
$WPFMISFolderButton.Add_Click( { Select-TargetDir })

#Driver Directory Buttons
$WPFDriverDir1Button.Add_Click( { Select-DriverSource -DriverTextBoxNumber $WPFDriverDir1TextBox })
$WPFDriverDir2Button.Add_Click( { Select-DriverSource -DriverTextBoxNumber $WPFDriverDir2TextBox })
$WPFDriverDir3Button.Add_Click( { Select-DriverSource -DriverTextBoxNumber $WPFDriverDir3TextBox })
$WPFDriverDir4Button.Add_Click( { Select-DriverSource -DriverTextBoxNumber $WPFDriverDir4TextBox })
$WPFDriverDir5Button.Add_Click( { Select-DriverSource -DriverTextBoxNumber $WPFDriverDir5TextBox })

#Make it So Button, which builds the WIM file
$WPFMISMakeItSoButton.Add_Click( { Invoke-MakeItSo -appx $global:SelectedAppx })

#Update OSDBuilder Button
$WPFUpdateOSDBUpdateButton.Add_Click( {
        Update-OSDB
        Update-OSDSUS
    })

#Update patch source
$WPFUpdatesDownloadNewButton.Add_Click( { Update-PatchSource })

#Select Appx packages to remove
$WPFAppxButton.Add_Click( { $global:SelectedAppx = Select-Appx })

#Select Autopilot path to save button
$WPFJSONButtonSavePath.Add_Click( { Select-NewJSONDir })

#retrieve autopilot profile from intune
$WPFJSONButtonRetrieve.Add_click( { get-wwautopilotprofile -login $WPFJSONTextBoxAADID.Text -path $WPFJSONTextBoxSavePath.Text })

#Button to save configuration file
$WPFSLSaveButton.Add_click( { Save-Configuration -filename $WPFSLSaveFileName.text })

#Button to load configuration file
$WPFSLLoadButton.Add_click( { Select-Config })

#Button to select ISO for importation
$WPFImportImportSelectButton.Add_click( { Select-ISO })

#Button to import content from iso
$WPFImportImportButton.Add_click( { Import-ISO })

#Combo Box dynamic change for Winver combo box
$WPFImportOtherCBWinOS.add_SelectionChanged({ Update-ImportVersionCB })

#Button to select the import path in the other components
$WPFImportOtherBSelectPath.add_click({ Select-ImportOtherPath

        if ($WPFImportOtherCBType.SelectedItem -ne 'Feature On Demand') {
            if ($WPFImportOtherCBWinOS.SelectedItem -ne 'Windows 11') { $items = (Get-ChildItem -Path $WPFImportOtherTBPath.text | Select-Object -Property Name | Out-GridView -Title 'Select Objects' -PassThru) }
            if (($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 11') -and ($WPFImportOtherCBType.SelectedItem -eq 'Language Pack')) { $items = (Get-ChildItem -Path $WPFImportOtherTBPath.text | Select-Object -Property Name | Where-Object { ($_.Name -like '*Windows-Client-Language-Pack*') } | Out-GridView -Title 'Select Objects' -PassThru) }
            if (($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 11') -and ($WPFImportOtherCBType.SelectedItem -eq 'Local Experience Pack')) { $items = (Get-ChildItem -Path $WPFImportOtherTBPath.text | Select-Object -Property Name | Out-GridView -Title 'Select Objects' -PassThru) }

        }

        if ($WPFImportOtherCBType.SelectedItem -eq 'Feature On Demand') {
            if ($WPFImportOtherCBWinOS.SelectedItem -ne 'Windows 11') { $items = (Get-ChildItem -Path $WPFImportOtherTBPath.text) }
            if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows 11') { $items = (Get-ChildItem -Path $WPFImportOtherTBPath.text | Select-Object -Property Name | Where-Object { ($_.Name -notlike '*Windows-Client-Language-Pack*') } | Out-GridView -Title 'Select Objects' -PassThru) }

        }


        $WPFImportOtherLBList.Items.Clear()
        $count = 0
        $path = $WPFImportOtherTBPath.text
        foreach ($item in $items) {
            $WPFImportOtherLBList.Items.Add($item.name)
            $count = $count + 1
        }

        if ($wpfImportOtherCBType.SelectedItem -eq 'Language Pack') { Update-Log -data "$count Language Packs selected from $path" -Class Information }
        if ($wpfImportOtherCBType.SelectedItem -eq 'Local Experience Pack') { Update-Log -data "$count Local Experience Packs selected from $path" -Class Information }
        if ($wpfImportOtherCBType.SelectedItem -eq 'Feature On Demand') { Update-Log -data "Features On Demand source selected from $path" -Class Information }

    })

#Button to import Other Components content
$WPFImportOtherBImport.add_click({
        if ($WPFImportOtherCBWinOS.SelectedItem -eq 'Windows Server') {
            if ($WPFImportOtherCBWinVer.SelectedItem -eq '2019') { $WinVerConversion = '1809' }
        }
        else {
            $WinVerConversion = $WPFImportOtherCBWinVer.SelectedItem
        }

        if ($WPFImportOtherCBType.SelectedItem -eq 'Language Pack') { Import-LanguagePacks -Winver $WinVerConversion -WinOS $WPFImportOtherCBWinOS.SelectedItem -LPSourceFolder $WPFImportOtherTBPath.text }
        if ($WPFImportOtherCBType.SelectedItem -eq 'Local Experience Pack') { Import-LocalExperiencePack -Winver $WinVerConversion -WinOS $WPFImportOtherCBWinOS.SelectedItem -LPSourceFolder $WPFImportOtherTBPath.text }
        if ($WPFImportOtherCBType.SelectedItem -eq 'Feature On Demand') { Import-FeatureOnDemand -Winver $WinVerConversion -WinOS $WPFImportOtherCBWinOS.SelectedItem -LPSourceFolder $WPFImportOtherTBPath.text } })

#Button Select LP's for importation
$WPFCustomBLangPacksSelect.add_click({ Select-LPFODCriteria -type 'LP' })

#Button to select FODs for importation
$WPFCustomBFODSelect.add_click({ Select-LPFODCriteria -type 'FOD' })

#Button to select LXPs for importation
$WPFCustomBLEPSelect.add_click({ Select-LPFODCriteria -type 'LXP' })

#Button to select PS1 script
$WPFCustomBSelectPath.add_click({
        $Script = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = [Environment]::GetFolderPath('Desktop')
            Filter           = 'PS1 (*.ps1)|'
        }
        $null = $Script.ShowDialog()
        $WPFCustomTBFile.text = $Script.FileName })

#Button to Select ConfigMgr Image Package
$WPFCMBSelectImage.Add_Click({
        $image = (Get-WmiObject -Namespace "root\SMS\Site_$($global:SiteCode)" -Class SMS_ImagePackage -ComputerName $global:SiteServer) | Select-Object -Property Name, version, language, ImageOSVersion, PackageID, Description | Out-GridView -Title 'Pick an image' -PassThru
        $path = $PSScriptRoot + '\ConfigMgr\PackageInfo\' + $image.packageid
        if ((Test-Path -Path $path ) -eq $True) {
            # write-host "True"
            Get-Configuration -filename $path
        }
        else {
            Get-ImageInfo -PackID $image.PackageID
        }
    })

#Button to select new file path (may not need)
#$WPFCMBFilePathSelect.Add_Click({ })

#Button to add DP/DPG to list box on ConfigMgr tab
$WPFCMBAddDP.Add_Click({ Select-DistributionPoints })

#Button to remove DP/DPG from list box on ConfigMgr tab
$WPFCMBRemoveDP.Add_Click({

        while ($WPFCMLBDPs.SelectedItems) {
            $WPFCMLBDPs.Items.Remove($WPFCMLBDPs.SelectedItems[0])
        }

    })

#Combo Box dynamic change ConfigMgr type
$WPFCMCBImageType.add_SelectionChanged({ Enable-ConfigMgrOptions })

#Combo Box Software Update Catalog source
$WPFUSCBSelectCatalogSource.add_SelectionChanged({ Invoke-UpdateTabOptions })

#Button to remove items from Language Packs List Box
$WPFCustomBLangPacksRemove.Add_Click({

        while ($WPFCustomLBLangPacks.SelectedItems) {
            $WPFCustomLBLangPacks.Items.Remove($WPFCustomLBLangPacks.SelectedItems[0])
        }
    })

#Button to remove items from LXP List Box
$WPFCustomBLEPSRemove.Add_Click({

        while ($WPFCustomLBLEP.SelectedItems) {
            $WPFCustomLBLEP.Items.Remove($WPFCustomLBLEP.SelectedItems[0])
        }

    })

#Button to remove items from FOD List Box
$WPFCustomBFODRemove.Add_Click({

        while ($WPFCustomLBFOD.SelectedItems) {
            $WPFCustomLBFOD.Items.Remove($WPFCustomLBFOD.SelectedItems[0])
        }

    })

#Button to select default app association XML
$WPFCustomBDefaultApp.Add_Click({ Select-DefaultApplicationAssociations })

#Button to select start menu XML
$WPFCustomBStartMenu.Add_Click({ Select-StartMenu })

#Button to select registry files
$WPFCustomBRegistryAdd.Add_Click({ Select-RegFiles })

#Button to remove registry files
$WPFCustomBRegistryRemove.Add_Click({

        while ($WPFCustomLBRegistry.SelectedItems) {
            $WPFCustomLBRegistry.Items.Remove($WPFCustomLBRegistry.SelectedItems[0])
        }

    })

#Button to select ISO save folder
$WPFMISISOSelectButton.Add_Click({ Select-ISODirectory })

#Button to install CM Console Extension
$WPFCMBInstallExtensions.Add_Click({ Install-WWCMConsoleExtension })

#Button to set CM Site and Server properties
$WPFCMBSetCM.Add_Click({
        Set-ConfigMgr
        Import-CMModule

    })

#Button to tell dad joke - unanimously requested by WW users at MMSMOA 2022
$WPFImportBDJ.Add_Click({
        $joke = Invoke-DadJoke
        $DadjokePrompt = ([System.Windows.MessageBox]::Show($joke, "Hi hungry, I'm Dad", 'OK'))
    })

#===========================================================================
# Section for Checkboxes to call Functions
#===========================================================================

#Enable JSON Selection
$WPFJSONEnableCheckBox.Add_Click( {
        If ($WPFJSONEnableCheckBox.IsChecked -eq $true) {
            $WPFJSONButton.IsEnabled = $True
            $WPFMISJSONTextBox.Text = 'True'
        }
        else {
            $WPFJSONButton.IsEnabled = $False
            $WPFMISJSONTextBox.Text = 'False'
        }
    })

#Enable Driver Selection
$WPFDriverCheckBox.Add_Click( {
        If ($WPFDriverCheckBox.IsChecked -eq $true) {
            $WPFDriverDir1Button.IsEnabled = $True
            $WPFDriverDir2Button.IsEnabled = $True
            $WPFDriverDir3Button.IsEnabled = $True
            $WPFDriverDir4Button.IsEnabled = $True
            $WPFDriverDir5Button.IsEnabled = $True
            $WPFMISDriverTextBox.Text = 'True'
        }
        else {
            $WPFDriverDir1Button.IsEnabled = $False
            $WPFDriverDir2Button.IsEnabled = $False
            $WPFDriverDir3Button.IsEnabled = $False
            $WPFDriverDir4Button.IsEnabled = $False
            $WPFDriverDir5Button.IsEnabled = $False
            $WPFMISDriverTextBox.Text = 'False'
        }
    })

#Enable Updates Selection
$WPFUpdatesEnableCheckBox.Add_Click( {
        If ($WPFUpdatesEnableCheckBox.IsChecked -eq $true) {
            $WPFMISUpdatesTextBox.Text = 'True'
        }
        else {
            $WPFMISUpdatesTextBox.Text = 'False'
        }
    })

#Enable AppX Selection
$WPFAppxCheckBox.Add_Click( {
        If ($WPFAppxCheckBox.IsChecked -eq $true) {
            $WPFAppxButton.IsEnabled = $True
            $WPFMISAppxTextBox.Text = 'True'
        }
        else {
            $WPFAppxButton.IsEnabled = $False
        }
    })

#Enable install.wim selection in import
$WPFImportWIMCheckBox.Add_Click( {
        If ($WPFImportWIMCheckBox.IsChecked -eq $true) {
            $WPFImportNewNameTextBox.IsEnabled = $True
            $WPFImportImportButton.IsEnabled = $True
        }
        else {
            $WPFImportNewNameTextBox.IsEnabled = $False
            if ($WPFImportDotNetCheckBox.IsChecked -eq $False) { $WPFImportImportButton.IsEnabled = $False }
        }
    })

#Enable .Net binaries selection in import
$WPFImportDotNetCheckBox.Add_Click( {
        If ($WPFImportDotNetCheckBox.IsChecked -eq $true) {
            $WPFImportImportButton.IsEnabled = $True
        }
        else {
            if ($WPFImportWIMCheckBox.IsChecked -eq $False) { $WPFImportImportButton.IsEnabled = $False }
        }
    })

#Enable Win10 version selection
$WPFUpdatesW10Main.Add_Click( {
        If ($WPFUpdatesW10Main.IsChecked -eq $true) {
            #$WPFUpdatesW10_1909.IsEnabled = $True
            $WPFUpdatesW10_1903.IsEnabled = $True
            $WPFUpdatesW10_1809.IsEnabled = $True
            $WPFUpdatesW10_1803.IsEnabled = $True
            $WPFUpdatesW10_1709.IsEnabled = $True
            $WPFUpdatesW10_2004.IsEnabled = $True
            $WPFUpdatesW10_20H2.IsEnabled = $True
            $WPFUpdatesW10_21H1.IsEnabled = $True
            $WPFUpdatesW10_21H2.IsEnabled = $True
            $WPFUpdatesW10_22H2.IsEnabled = $True
        }
        else {
            #$WPFUpdatesW10_1909.IsEnabled = $False
            $WPFUpdatesW10_1903.IsEnabled = $False
            $WPFUpdatesW10_1809.IsEnabled = $False
            $WPFUpdatesW10_1803.IsEnabled = $False
            $WPFUpdatesW10_1709.IsEnabled = $False
            $WPFUpdatesW10_2004.IsEnabled = $False
            $WPFUpdatesW10_20H2.IsEnabled = $False
            $WPFUpdatesW10_21H1.IsEnabled = $False
            $WPFUpdatesW10_21H2.IsEnabled = $False
            $WPFUpdatesW10_22H2.IsEnabled = $False
        }
    })

#Enable Win11 version selection
$WPFUpdatesW11Main.Add_Click( {
        If ($WPFUpdatesW11Main.IsChecked -eq $true) {
            $WPFUpdatesW11_21H2.IsEnabled = $True
            $WPFUpdatesW11_22H2.IsEnabled = $True
        }
        else {
            $WPFUpdatesW11_21H2.IsEnabled = $False
            $WPFUpdatesW11_22H2.IsEnabled = $False

        }
    })

#Enable LP Selection
$WPFCustomCBLangPacks.Add_Click({
        If ($WPFCustomCBLangPacks.IsChecked -eq $true) {
            $WPFCustomBLangPacksSelect.IsEnabled = $True
            $WPFCustomBLangPacksRemove.IsEnabled = $True
        }
        else {
            $WPFCustomBLangPacksSelect.IsEnabled = $False
            $WPFCustomBLangPacksRemove.IsEnabled = $False
        }
    })

#ENable Language Experience Pack selection
$WPFCustomCBLEP.Add_Click({
        If ($WPFCustomCBLEP.IsChecked -eq $true) {
            $WPFCustomBLEPSelect.IsEnabled = $True
            $WPFCustomBLEPSRemove.IsEnabled = $True
        }
        else {
            $WPFCustomBLEPSelect.IsEnabled = $False
            $WPFCustomBLEPSRemove.IsEnabled = $False
        }
    })

#Enable Feature On Demand selection
$WPFCustomCBFOD.Add_Click({
        If ($WPFCustomCBFOD.IsChecked -eq $true) {
            $WPFCustomBFODSelect.IsEnabled = $True
            $WPFCustomBFODRemove.IsEnabled = $True
        }
        else {
            $WPFCustomBFODSelect.IsEnabled = $False
            $WPFCustomBFODRemove.IsEnabled = $False
        }
    })

#Enable Run Script settings
$WPFCustomCBRunScript.Add_Click({
        If ($WPFCustomCBRunScript.IsChecked -eq $true) {
            $WPFCustomTBFile.IsEnabled = $True
            $WPFCustomBSelectPath.IsEnabled = $True
            $WPFCustomTBParameters.IsEnabled = $True
            $WPFCustomCBScriptTiming.IsEnabled = $True
        }
        else {
            $WPFCustomTBFile.IsEnabled = $False
            $WPFCustomBSelectPath.IsEnabled = $False
            $WPFCustomTBParameters.IsEnabled = $False
            $WPFCustomCBScriptTiming.IsEnabled = $False
        } })

#Enable Default App Association
$WPFCustomCBEnableApp.Add_Click({
        If ($WPFCustomCBEnableApp.IsChecked -eq $true) {
            $WPFCustomBDefaultApp.IsEnabled = $True

        }
        else {
            $WPFCustomBDefaultApp.IsEnabled = $False
        }
    })

#Enable Start Menu Layout
$WPFCustomCBEnableStart.Add_Click({
        If ($WPFCustomCBEnableStart.IsChecked -eq $true) {
            $WPFCustomBStartMenu.IsEnabled = $True

        }
        else {
            $WPFCustomBStartMenu.IsEnabled = $False
        }
    })

#Enable Registry selection list box buttons
$WPFCustomCBEnableRegistry.Add_Click({
        If ($WPFCustomCBEnableRegistry.IsChecked -eq $true) {
            $WPFCustomBRegistryAdd.IsEnabled = $True
            $WPFCustomBRegistryRemove.IsEnabled = $True
            $WPFCustomLBRegistry.IsEnabled = $True

        }
        else {
            $WPFCustomBRegistryAdd.IsEnabled = $False
            $WPFCustomBRegistryRemove.IsEnabled = $False
            $WPFCustomLBRegistry.IsEnabled = $False

        }
    })

#Enable ISO/Upgrade Package selection in import
$WPFImportISOCheckBox.Add_Click( {
        If ($WPFImportISOCheckBox.IsChecked -eq $true) {
            $WPFImportImportButton.IsEnabled = $True
        }
        else {
            if (($WPFImportWIMCheckBox.IsChecked -eq $False) -and ($WPFImportDotNetCheckBox.IsChecked -eq $False)) { $WPFImportImportButton.IsEnabled = $False }
        }
    })

#Enable not creating stand alone wim
$WPFMISCBNoWIM.Add_Click( {
        If ($WPFMISCBNoWIM.IsChecked -eq $true) {
            $WPFMISWimNameTextBox.IsEnabled = $False
            $WPFMISWimFolderTextBox.IsEnabled = $False
            $WPFMISFolderButton.IsEnabled = $False

            $WPFMISWimNameTextBox.text = 'install.wim'
        }
        else {
            $WPFMISWimNameTextBox.IsEnabled = $True
            $WPFMISWimFolderTextBox.IsEnabled = $True
            $WPFMISFolderButton.IsEnabled = $True
        }
    })

#Enable ISO creation fields
$WPFMISCBISO.Add_Click( {
        If ($WPFMISCBISO.IsChecked -eq $true) {
            $WPFMISTBISOFileName.IsEnabled = $True
            $WPFMISTBFilePath.IsEnabled = $True
            $WPFMISCBDynamicUpdates.IsEnabled = $True
            $WPFMISCBNoWIM.IsEnabled = $True
            $WPFMISCBBootWIM.IsEnabled = $True
            $WPFMISISOSelectButton.IsEnabled = $true

        }
        else {
            $WPFMISTBISOFileName.IsEnabled = $False
            $WPFMISTBFilePath.IsEnabled = $False
            $WPFMISISOSelectButton.IsEnabled = $false

        }
        if (($WPFMISCBISO.IsChecked -eq $false) -and ($WPFMISCBUpgradePackage.IsChecked -eq $false)) {
            $WPFMISCBDynamicUpdates.IsEnabled = $False
            $WPFMISCBDynamicUpdates.IsChecked = $False
            $WPFMISCBNoWIM.IsEnabled = $False
            $WPFMISCBNoWIM.IsChecked = $False
            $WPFMISWimNameTextBox.IsEnabled = $true
            $WPFMISWimFolderTextBox.IsEnabled = $true
            $WPFMISFolderButton.IsEnabled = $true
            $WPFMISCBBootWIM.IsChecked = $false
            $WPFMISCBBootWIM.IsEnabled = $false
        }
    })

#Enable upgrade package path option
$WPFMISCBUpgradePackage.Add_Click( {
        If ($WPFMISCBUpgradePackage.IsChecked -eq $true) {
            $WPFMISTBUpgradePackage.IsEnabled = $True
            $WPFMISCBDynamicUpdates.IsEnabled = $True
            $WPFMISCBNoWIM.IsEnabled = $True
            $WPFMISCBBootWIM.IsEnabled = $True

        }
        else {
            $WPFMISTBUpgradePackage.IsEnabled = $False
        }
        if (($WPFMISCBISO.IsChecked -eq $false) -and ($WPFMISCBUpgradePackage.IsChecked -eq $false)) {
            $WPFMISCBDynamicUpdates.IsEnabled = $False
            $WPFMISCBDynamicUpdates.IsChecked = $False
            $WPFMISCBNoWIM.IsEnabled = $False
            $WPFMISCBNoWIM.IsChecked = $False
            $WPFMISWimNameTextBox.IsEnabled = $true
            $WPFMISWimFolderTextBox.IsEnabled = $true
            $WPFMISFolderButton.IsEnabled = $true
            $WPFMISCBBootWIM.IsChecked = $false
            $WPFMISCBBootWIM.IsEnabled = $false
        }
    })

#Enable option to include Optional Updates
$WPFUpdatesEnableCheckBox.Add_Click({
        if ($WPFUpdatesEnableCheckBox.IsChecked -eq $true) { $WPFUpdatesOptionalEnableCheckBox.IsEnabled = $True }
        else {
            $WPFUpdatesOptionalEnableCheckBox.IsEnabled = $False
            $WPFUpdatesOptionalEnableCheckBox.IsChecked = $False
        }
    })

#==========================================================
#Run WIM Witch below
#==========================================================

#Runs WIM Witch from a single file, bypassing the GUI
if (($auto -eq $true) -and ($autofile -ne '')) {
    Invoke-RunConfigFile -filename $autofile
    Show-ClosingText
    exit 0
}

#Runs WIM from a path with multiple files, bypassing the GUI
if (($auto -eq $true) -and ($autopath -ne '')) {
    Update-Log -data "Running batch job from config folder $autopath" -Class Information
    $files = Get-ChildItem -Path $autopath
    Update-Log -data 'Setting batch job for the folling configs:' -Class Information
    foreach ($file in $files) { Update-Log -Data $file -Class Information }
    foreach ($file in $files) {
        $fullpath = $autopath + '\' + $file
        Invoke-RunConfigFile -filename $fullpath
    }
    Update-Log -Data 'Work complete' -Class Information
    Show-ClosingText
    exit 0
}

#Loads the specified ConfigMgr config file from CM Console
if (($CM -eq 'Edit') -and ($autofile -ne '')) {
    Update-Log -Data 'Loading ConfigMgr OS Image Package information...' -Class Information
    Get-Configuration -filename $autofile
}

#Closing action for the WPF form
Register-ObjectEvent -InputObject $form -EventName Closed -Action ( { Show-ClosingText }) | Out-Null

#display text information to the user
Invoke-TextNotification

if ($HiHungryImDad -eq $true) {
    $string = Invoke-DadJoke
    Update-Log -Data $string -Class Comment
    $WPFImportBDJ.Visibility = 'Visible'
}

#Start GUI
Update-Log -data 'Starting WIM Witch GUI' -class Information
$Form.ShowDialog() | Out-Null #This starts the GUI

#endregion Main