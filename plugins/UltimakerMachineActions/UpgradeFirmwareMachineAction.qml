// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

import UM 1.2 as UM
import Cura 1.0 as Cura


Cura.MachineAction
{
    anchors.fill: parent;
    Item
    {
        id: upgradeFirmwareMachineAction
        anchors.fill: parent;
        UM.I18nCatalog { id: catalog; name:"cura"}

        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Upgrade Firmware")
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }
        Label
        {
            id: pageDescription
            anchors.top: pageTitle.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Firmware is the piece of software running directly on your 3D printer. This firmware controls the step motors, regulates the temperature and ultimately makes your printer work.")
        }

        Label
        {
            id: upgradeText1
            anchors.top: pageDescription.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "The firmware shipping with new Ultimakers works, but upgrades have been made to make better prints, and make calibration easier.");
        }

        Label
        {
            id: upgradeText2
            anchors.top: upgradeText1.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "Cura requires these new features and thus your firmware will most likely need to be upgraded. You can do so now.");
        }
        Item
        {
            anchors.top: upgradeText2.bottom
            anchors.topMargin: UM.Theme.getSize("default_margin").height
            anchors.horizontalCenter: parent.horizontalCenter
            width: upgradeButton.width + skipUpgradeButton.width + UM.Theme.getSize("default_margin").height < upgradeFirmwareMachineAction.width ? upgradeButton.width + skipUpgradeButton.width + UM.Theme.getSize("default_margin").height : upgradeFirmwareMachineAction.width
            Button
            {
                id: upgradeButton
                anchors.top: parent.top
                anchors.left: parent.left
                text: catalog.i18nc("@action:button","Upgrade to Marlin Firmware");
                onClicked: Cura.USBPrinterManager.updateAllFirmware()
            }
            Button
            {
                id: skipUpgradeButton
                anchors.top: parent.width < upgradeFirmwareMachineAction.width ? parent.top : upgradeButton.bottom
                anchors.topMargin: parent.width < upgradeFirmwareMachineAction.width ? 0 : UM.Theme.getSize("default_margin").height / 2
                anchors.left: parent.width < upgradeFirmwareMachineAction.width ? upgradeButton.right : parent.left
                anchors.leftMargin: parent.width < upgradeFirmwareMachineAction.width ? UM.Theme.getSize("default_margin").width : 0
                text: catalog.i18nc("@action:button", "Skip Upgrade");
                onClicked: manager.setFinished()
            }
        }
    }
}