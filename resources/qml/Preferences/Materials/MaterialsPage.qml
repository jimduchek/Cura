// Copyright (c) 2022 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import UM 1.5 as UM
import Cura 1.5 as Cura

Item
{
    id: base

    // Keep PreferencesDialog happy
    property var resetEnabled: false
    property var currentItem: null

    property var materialManagementModel: CuraApplication.getMaterialManagementModel()

    property var hasCurrentItem: base.currentItem != null
    property var isCurrentItemActivated:
    {
        if (!hasCurrentItem)
        {
            return false
        }
        const extruder_position = Cura.ExtruderManager.activeExtruderIndex
        const root_material_id = Cura.MachineManager.currentRootMaterialId[extruder_position]
        return base.currentItem.root_material_id == root_material_id
    }
    property string newRootMaterialIdToSwitchTo: ""
    property bool toActivateNewMaterial: false

    property var extruder_position: Cura.ExtruderManager.activeExtruderIndex
    property var active_root_material_id: Cura.MachineManager.currentRootMaterialId[extruder_position]

    UM.I18nCatalog
    {
        id: catalog
        name: "cura"
    }

    function resetExpandedActiveMaterial()
    {
        materialListView.expandActiveMaterial(active_root_material_id)
    }

    function setExpandedActiveMaterial(root_material_id)
    {
        materialListView.expandActiveMaterial(root_material_id)
    }

    // When loaded, try to select the active material in the tree
    Component.onCompleted:
    {
        resetExpandedActiveMaterial()
        base.newRootMaterialIdToSwitchTo = active_root_material_id
    }

    // Every time the selected item has changed, notify to the details panel
    onCurrentItemChanged:
    {
        forceActiveFocus()
        if(materialDetailsPanel.currentItem != currentItem)
        {
            materialDetailsPanel.currentItem = currentItem
            // CURA-6679 If the current item is gone after the model update, reset the current item to the active material.
            if (currentItem == null)
            {
                resetExpandedActiveMaterial()
            }
        }
    }

    // Main layout
    Label
    {
        id: titleLabel
        anchors
        {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 5 * screenScaleFactor
        }
        font.pointSize: 18
        text: catalog.i18nc("@title:tab", "Materials")
    }

    // Button Row
    Row
    {
        id: buttonRow
        anchors
        {
            left: parent.left
            right: parent.right
            top: titleLabel.bottom
        }
        height: childrenRect.height

        // Activate button
        Button
        {
            id: activateMenuButton
            text: catalog.i18nc("@action:button", "Activate")
            icon.name: "list-activate"
            enabled: !isCurrentItemActivated && Cura.MachineManager.activeMachine.hasMaterials
            onClicked:
            {
                forceActiveFocus()

                // Set the current material as the one to be activated (needed to force the UI update)
                base.newRootMaterialIdToSwitchTo = base.currentItem.root_material_id
                const extruder_position = Cura.ExtruderManager.activeExtruderIndex
                Cura.MachineManager.setMaterial(extruder_position, base.currentItem.container_node)
            }
        }

        // Create button
        Button
        {
            id: createMenuButton
            text: catalog.i18nc("@action:button", "Create")
            icon.name: "list-add"
            enabled: Cura.MachineManager.activeMachine.hasMaterials
            onClicked:
            {
                forceActiveFocus();
                base.newRootMaterialIdToSwitchTo = base.materialManagementModel.createMaterial();
                base.toActivateNewMaterial = true;
            }
        }

        // Duplicate button
        Button
        {
            id: duplicateMenuButton
            text: catalog.i18nc("@action:button", "Duplicate");
            icon.name: "list-add"
            enabled: base.hasCurrentItem
            onClicked:
            {
                forceActiveFocus();
                base.newRootMaterialIdToSwitchTo = base.materialManagementModel.duplicateMaterial(base.currentItem.container_node);
                base.toActivateNewMaterial = true;
            }
        }

        // Remove button
        Button
        {
            id: removeMenuButton
            text: catalog.i18nc("@action:button", "Remove")
            icon.name: "list-remove"
            enabled: base.hasCurrentItem && !base.currentItem.is_read_only && !base.isCurrentItemActivated && base.materialManagementModel.canMaterialBeRemoved(base.currentItem.container_node)

            onClicked:
            {
                forceActiveFocus();
                confirmRemoveMaterialDialog.open();
            }
        }

        // Import button
        Button
        {
            id: importMenuButton
            text: catalog.i18nc("@action:button", "Import")
            icon.name: "document-import"
            onClicked:
            {
                forceActiveFocus();
                importMaterialDialog.open();
            }
            enabled: Cura.MachineManager.activeMachine.hasMaterials
        }

        // Export button
        Button
        {
            id: exportMenuButton
            text: catalog.i18nc("@action:button", "Export")
            icon.name: "document-export"
            onClicked:
            {
                forceActiveFocus();
                exportMaterialDialog.open();
            }
            enabled: base.hasCurrentItem
        }

        //Sync button.
        Button
        {
            id: syncMaterialsButton
            text: catalog.i18nc("@action:button Sending materials to printers", "Sync with Printers")
            icon.name: "sync-synchronizing"
            onClicked:
            {
                forceActiveFocus();
                base.materialManagementModel.openSyncAllWindow();
            }
            visible: Cura.MachineManager.activeMachine.supportsMaterialExport
        }
    }

    Item
    {
        id: contentsItem
        anchors
        {
            top: titleLabel.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5 * screenScaleFactor
            bottomMargin: 0
        }
        clip: true
    }

    Item
    {
        anchors
        {
            top: buttonRow.bottom
            topMargin: UM.Theme.getSize("default_margin").height
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        SystemPalette { id: palette }

        Label
        {
            id: captionLabel
            anchors
            {
                top: parent.top
                left: parent.left
            }
            visible: text != ""
            text:
            {
                var caption = catalog.i18nc("@action:label", "Printer") + ": " + Cura.MachineManager.activeMachine.name;
                if (Cura.MachineManager.activeMachine.hasVariants)
                {
                    var activeVariantName = ""
                    if(Cura.MachineManager.activeStack != null)
                    {
                        activeVariantName = Cura.MachineManager.activeStack.variant.name
                    }
                    caption += ", " + Cura.MachineManager.activeDefinitionVariantsName + ": " + activeVariantName;
                }
                return caption;
            }
            width: materialScrollView.width
            elide: Text.ElideRight
        }

        ScrollView
        {
            id: materialScrollView
            anchors
            {
                top: captionLabel.visible ? captionLabel.bottom : parent.top
                topMargin: captionLabel.visible ? UM.Theme.getSize("default_margin").height : 0
                bottom: parent.bottom
                left: parent.left
            }
            width: (parent.width * 0.4) | 0

            clip: true
            ScrollBar.vertical: UM.ScrollBar
            {
                id: materialScrollBar
                parent: materialScrollView
                anchors
                {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }
            }
            contentHeight: materialListView.height //For some reason, this is not determined automatically with this ScrollView. Very weird!

            MaterialsList
            {
                id: materialListView
                width: materialScrollView.width - materialScrollBar.width
            }
        }

        MaterialsDetailsPanel
        {
            id: materialDetailsPanel
            anchors
            {
                left: materialScrollView.right
                leftMargin: UM.Theme.getSize("default_margin").width
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
        }
    }

    // Dialogs
    Cura.MessageDialog
    {
        id: confirmRemoveMaterialDialog
        title: catalog.i18nc("@title:window", "Confirm Remove")
        property string materialName: base.currentItem !== null ? base.currentItem.name : ""

        text: catalog.i18nc("@label (%1 is object name)", "Are you sure you wish to remove %1? This cannot be undone!").arg(materialName)
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted:
        {
            // Set the active material as the fallback. It will be selected when the current material is deleted
            base.newRootMaterialIdToSwitchTo = base.active_root_material_id
            base.materialManagementModel.removeMaterial(base.currentItem.container_node);
        }
    }

    FileDialog
    {
        id: importMaterialDialog
        title: catalog.i18nc("@title:window", "Import Material")
        selectExisting: true
        nameFilters: Cura.ContainerManager.getContainerNameFilters("material")
        folder: CuraApplication.getDefaultPath("dialog_material_path")
        onAccepted:
        {
            const result = Cura.ContainerManager.importMaterialContainer(fileUrl);

            const messageDialog = Qt.createQmlObject("import Cura 1.5 as Cura; Cura.MessageDialog { onClosed: destroy() }", base);
            messageDialog.standardButtons = Dialog.Ok;
            messageDialog.title = catalog.i18nc("@title:window", "Import Material");
            switch (result.status)
            {
                case "success":
                    messageDialog.text = catalog.i18nc("@info:status Don't translate the XML tag <filename>!", "Successfully imported material <filename>%1</filename>").arg(fileUrl);
                    break;
                default:
                    messageDialog.text = catalog.i18nc("@info:status Don't translate the XML tags <filename> or <message>!", "Could not import material <filename>%1</filename>: <message>%2</message>").arg(fileUrl).arg(result.message);
                    break;
            }
            messageDialog.open();
            CuraApplication.setDefaultPath("dialog_material_path", folder);
        }
    }

    FileDialog
    {
        id: exportMaterialDialog
        title: catalog.i18nc("@title:window", "Export Material")
        selectExisting: false
        nameFilters: Cura.ContainerManager.getContainerNameFilters("material")
        folder: CuraApplication.getDefaultPath("dialog_material_path")
        onAccepted:
        {
            const result = Cura.ContainerManager.exportContainer(base.currentItem.root_material_id, selectedNameFilter, fileUrl);

            const messageDialog = Qt.createQmlObject("import Cura 1.5 as Cura; Cura.MessageDialog { onClosed: destroy() }", base);
            messageDialog.title = catalog.i18nc("@title:window", "Export Material");
            messageDialog.standardButtons = Dialog.Ok;
            switch (result.status)
            {
                case "error":
                    messageDialog.text = catalog.i18nc("@info:status Don't translate the XML tags <filename> and <message>!", "Failed to export material to <filename>%1</filename>: <message>%2</message>").arg(fileUrl).arg(result.message);
                    break;
                case "success":
                    messageDialog.text = catalog.i18nc("@info:status Don't translate the XML tag <filename>!", "Successfully exported material to <filename>%1</filename>").arg(result.path);
                    break;
            }
            messageDialog.open();

            CuraApplication.setDefaultPath("dialog_material_path", folder);
        }
    }
}
