// Copyright (c) 2021 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.0

import UM 1.5 as UM

SettingItem
{
    id: base
    property var focusItem: input

    property string textBeforeEdit
    property bool textHasChanged
    property bool focusGainedByClick: false
    onFocusReceived:
    {
        textHasChanged = false;
        textBeforeEdit = focusItem.text;

        if(!focusGainedByClick)
        {
            // select all text when tabbing through fields (but not when selecting a field with the mouse)
            focusItem.selectAll();
        }
    }

    contents: UM.UnderlineBackground
    {
        id: control

        anchors.fill: parent

        liningColor:
        {
            if(!enabled)
            {
                return UM.Theme.getColor("text_field_border_disabled")
            }
            switch(propertyProvider.properties.validationState)
            {
                case "ValidatorState.Invalid":
                case "ValidatorState.Exception":
                case "ValidatorState.MinimumError":
                case "ValidatorState.MaximumError":
                    return UM.Theme.getColor("setting_validation_error");
                case "ValidatorState.MinimumWarning":
                case "ValidatorState.MaximumWarning":
                    return UM.Theme.getColor("setting_validation_warning");
            }
            //Validation is OK.
            if(hovered || input.activeFocus)
            {
                return UM.Theme.getColor("text_field_border_hovered")
            }
            return UM.Theme.getColor("text_field_border")
        }

        color: {
            if(!enabled)
            {
                return UM.Theme.getColor("text_field")
            }
            switch(propertyProvider.properties.validationState)
            {
                case "ValidatorState.Invalid":
                case "ValidatorState.Exception":
                case "ValidatorState.MinimumError":
                case "ValidatorState.MaximumError":
                    return UM.Theme.getColor("setting_validation_error_background")
                case "ValidatorState.MinimumWarning":
                case "ValidatorState.MaximumWarning":
                    return UM.Theme.getColor("setting_validation_warning_background")
                case "ValidatorState.Valid":
                    return UM.Theme.getColor("setting_validation_ok")

                default:
                    return UM.Theme.getColor("text_field")
            }
        }

        UM.Label
        {
            anchors
            {
                left: parent.left
                leftMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                right: parent.right
                rightMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                verticalCenter: parent.verticalCenter
            }

            text: definition.unit
            //However the setting value is aligned, align the unit opposite. That way it stays readable with right-to-left languages.
            horizontalAlignment: (input.effectiveHorizontalAlignment == Text.AlignLeft) ? Text.AlignRight : Text.AlignLeft
            textFormat: Text.PlainText
            color: UM.Theme.getColor("setting_unit")
        }

        TextInput
        {
            id: input

            anchors
            {
                left: parent.left
                leftMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                right: parent.right
                rightMargin: Math.round(UM.Theme.getSize("setting_unit_margin").width)
                verticalCenter: parent.verticalCenter
            }
            renderType: Text.NativeRendering

            Keys.onTabPressed:
            {
                base.setActiveFocusToNextSetting(true)
            }
            Keys.onBacktabPressed:
            {
                base.setActiveFocusToNextSetting(false)
            }

            Keys.onReleased:
            {
                if (text != textBeforeEdit)
                {
                    textHasChanged = true;
                }
                if (textHasChanged)
                {
                    propertyProvider.setPropertyValue("value", text)
                }
            }

            onActiveFocusChanged:
            {
                if(activeFocus)
                {
                    base.focusReceived();
                }
                base.focusGainedByClick = false;
            }

            color: !enabled ? UM.Theme.getColor("setting_control_disabled_text") : UM.Theme.getColor("setting_control_text")
            selectedTextColor: UM.Theme.getColor("setting_control_text")
            font: UM.Theme.getFont("default")
            selectionColor: UM.Theme.getColor("text_selection")
            selectByMouse: true

            maximumLength: (definition.type == "str" || definition.type == "[int]") ? -1 : 10

            // Since [int] & str don't have a max length, they need to be clipped (since clipping is expensive, this
            // should be done as little as possible)
            clip: definition.type == "str" || definition.type == "[int]"

            validator: RegExpValidator { regExp: (definition.type == "[int]") ? /^\[?(\s*-?[0-9]{0,9}\s*,)*(\s*-?[0-9]{0,9})\s*\]?$/ : (definition.type == "int") ? /^-?[0-9]{0,10}$/ : (definition.type == "float") ? /^-?[0-9]{0,9}[.,]?[0-9]{0,3}$/ : /^.*$/ } // definition.type property from parent loader used to disallow fractional number entry

            Binding
            {
                target: input
                property: "text"
                value:
                {
                    // Stacklevels
                    // 0: user  -> unsaved change
                    // 1: quality changes  -> saved change
                    // 2: quality
                    // 3: material  -> user changed material in materialspage
                    // 4: variant
                    // 5: machine_changes
                    // 6: machine
                    if ((base.resolve != "None" && base.resolve) && (stackLevel != 0) && (stackLevel != 1))
                    {
                        // We have a resolve function. Indicates that the setting is not settable per extruder and that
                        // we have to choose between the resolved value (default) and the global value
                        // (if user has explicitly set this).
                        return base.resolve
                    }
                    else {
                        return propertyProvider.properties.value
                    }
                }
                when: !input.activeFocus
            }

            MouseArea
            {
                id: mouseArea
                anchors.fill: parent

                cursorShape: Qt.IBeamCursor

                onPressed: {
                    if (!input.activeFocus)
                    {
                        base.focusGainedByClick = true
                        input.forceActiveFocus()
                    }
                    mouse.accepted = false
                }
            }
        }
    }
}
