import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0
import "../../items"

Page {
    id:root
    property string settingsUiPath:  "/apps/depecher/ui"
    property string settingsPath: "/apps/depecher/"

    MsgPageSettings {
        id: msgPageSettings
    }
    property alias settingsBehavior: msgPageSettings.settingsBehavior
    property alias settingsUI: msgPageSettings.settingsUI
    property alias settingsUIMessage: msgPageSettings.settingsUIMessage

    ConfigurationValue {
        id:nightMode
        key:settingsUiPath + "/nightMode"
        defaultValue: false
    }
    ConfigurationValue {
        id:nightModeSchedule
        key:settingsUiPath + "/nightModeSchedule"
        defaultValue: false
    }
    ConfigurationValue {
        id:nightModeFrom
        key:settingsUiPath + "/nightModeFrom"
        defaultValue: "1900-01-01T22:00:00"
    }
    ConfigurationValue {
        id:nightModeTill
        key:settingsUiPath + "/nightModeTill"
        defaultValue: "1900-01-01T08:00:00"
    }
    ConfigurationValue {
        id:showVoiceMessageButton
        key:settingsUiPath + "/showVoiceMessageButton"
        defaultValue: true
    }
    ConfigurationValue {
        id:showCurrentTimeLabel
        key:settingsUiPath + "/showCurrentTimeLabel"
        defaultValue: true
    }

    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height
        Column {
            id:content
            width:parent.width
            spacing: Theme.paddingSmall
            PageHeader {
                title: qsTr("Appearance")
            }
            ListModel {
                id:messagingModel
                property variant chatType: {type:TdlibState.BasicGroup}
                property string userName: "Pavel Nurov"
                property string action: "Pavel is typing"
                ListElement {

                }
                ListElement {
                    is_outgoing: false
                    author: "Pavel Nurov"
                    sender_photo:false
                    message_type:MessagingModel.TEXT
                    date:124532454
                    content:"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                    sending_state:TdlibState.Sending_Pending
                    section:1533848400
                }
                ListElement {
                    is_outgoing: true
                    author: "Me"
                    sender_photo:false
                    message_type:MessagingModel.TEXT
                    date:124532484
                    content:"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                    sending_state:TdlibState.Sending_Read
                    section:1533848400
                }
            }

            PageHeader {
                id: nameplate
                title: settingsUI.hideNameplate ? "" : messagingModel.userName
                height: settingsUI.hideNameplate ? actionLabel.height + Theme.paddingMedium : Math.max(_preferredHeight, _titleItem.y + _titleItem.height + actionLabel.height + Theme.paddingMedium)
                Label {
                    id: actionLabel
                    width: parent.width - parent.leftMargin - parent.rightMargin
                    anchors {
                        top: settingsUI.hideNameplate ? parent.top : parent._titleItem.bottom
                        topMargin: settingsUI.hideNameplate ? Theme.paddingSmall : 0
                        right: parent.right
                        rightMargin: parent.rightMargin
                    }
                    text: messagingModel.action
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                    opacity: 0.8
                    horizontalAlignment: Text.AlignRight
                    truncationMode: TruncationMode.Fade
                }
            }
            SilicaListView {
                width: parent.width
                height: root.height/2 + Theme.itemSizeMedium - nameplate.height
                clip:true
                model:messagingModel
                topMargin:  -1 * (Theme.itemSizeExtraLarge )
                currentIndex: 1
                spacing: Theme.paddingSmall
                delegate: MessageItem {
                }
            }


            Separator {
                width: parent.width
                color: Theme.secondaryColor
            }

            Slider {
                id:radiusSlider
                width: parent.width
                minimumValue: 0
                maximumValue: 90
                stepSize:1
                valueText: value
                label: qsTr("Radius")
                value: settingsUIMessage.radius
                onValueChanged: settingsUIMessage.radius = value
            }
            Slider {
                id:opacitySlider
                width: parent.width
                minimumValue: 0
                maximumValue: 1
                stepSize: 0.1
                value: settingsUIMessage.opacity
                valueText: value.toFixed(1)
                label: qsTr("Opacity")
                onValueChanged: settingsUIMessage.opacity = value
            }
            BackgroundItem {
                id: incomingColorPickerButton
                width: parent.width
                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    height: parent.height
                    spacing: Theme.paddingMedium
                    Rectangle {
                        id: incomingColorIndicator
                        width: height
                        height: parent.height
                        color: outcomingColorIndicator.getColor(settingsUIMessage.incomingColor)
                    }
                    Label {
                        width: Math.min(paintedWidth,parent.width - incomingColorIndicator.width)
                        wrapMode: Text.WordWrap
                        text: qsTr("Incoming message background color")
                        font.pixelSize: Theme.fontSizeSmall
                        color: incomingColorPickerButton.down ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                onClicked: {
                    var page = pageStack.push("Sailfish.Silica.ColorPickerPage", { color: incomingColorIndicator.color,
                                                  colors:[Theme.primaryColor,Theme.secondaryColor,
                                                      Theme.highlightColor,Theme.highlightBackgroundColor,
                                                      Theme.secondaryHighlightColor,Theme.highlightDimmerColor]})
                    page.colorClicked.connect(function(color) {
                        settingsUIMessage.incomingColor = content.themeColorToInt(color)
                        pageStack.pop()
                    })
                }
            }

            BackgroundItem {
                id: outcomingColorPickerButton
                width: parent.width
                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    height: parent.height
                    spacing: Theme.paddingMedium
                    Rectangle {
                        id: outcomingColorIndicator
                        width: height
                        height: parent.height
                        color: getColor(settingsUIMessage.color)
                        function getColor(colorEnum) {
                            if(typeof colorEnum == "number") {
                                switch(colorEnum) {
                                case 0:
                                    return Theme.primaryColor
                                case 1:
                                    return Theme.secondaryColor
                                case 2:
                                    return Theme.highlightColor
                                case 3:
                                    return Theme.highlightBackgroundColor
                                case 4:
                                    return Theme.secondaryHighlightColor
                                case 5:
                                    return Theme.highlightDimmerColor
                                }
                            }
                            return colorEnum
                        }

                    }
                    Label {
                        width: Math.min(paintedWidth,parent.width - outcomingColorIndicator.width)
                        wrapMode: Text.WordWrap
                        text: qsTr("Outcoming message background color")
                        font.pixelSize: Theme.fontSizeSmall
                        color: outcomingColorPickerButton.down ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                onClicked: {
                    var page = pageStack.push("Sailfish.Silica.ColorPickerPage", { color: outcomingColorIndicator.color,
                                                  colors:[Theme.primaryColor,Theme.secondaryColor,
                                                      Theme.highlightColor,Theme.highlightBackgroundColor,
                                                      Theme.secondaryHighlightColor,Theme.highlightDimmerColor]
                                              })
                    page.colorClicked.connect(function(color) {
                        settingsUIMessage.color = content.themeColorToInt(color)
                        pageStack.pop()
                    })
                }
            }

            function themeColorToInt(color) {
                switch(color) {
                case Theme.primaryColor:
                    return 0
                case Theme.secondaryColor:
                    return 1
                case Theme.highlightColor:
                    return 2
                case Theme.highlightBackgroundColor:
                    return 3
                case Theme.secondaryHighlightColor:
                    return 4
                case Theme.highlightDimmerColor:
                    return 5
                default:
                    return color
                }
            }

            TextSwitch {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                checked: settingsUI.hideNameplate
                automaticCheck: false
                text: qsTr("Minimize nameplate")
                onClicked: {
                    settingsUI.hideNameplate = !checked
                    settingsUI.sync()
                }
            }
            TextSwitch {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                checked: settingsUIMessage.oneAligning
                automaticCheck: false
                text: qsTr("Always align messages to left")
                onClicked: {
                    settingsUIMessage.oneAligning = !checked
                    settingsUIMessage.sync()
                }
            }
            SectionHeader {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                text: qsTr("Miscellaneous")
            }
            TextSwitch {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                checked: settingsUIMessage.fullSizeInChannels
                automaticCheck: false
                text: qsTr("Show full screen images in channels")
                onClicked: {
                    settingsUIMessage.fullSizeInChannels = !checked
                    settingsUIMessage.sync()
                }
            }

            TextSwitch {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                checked: showVoiceMessageButton.value
                automaticCheck: false
                text: qsTr("Show voice message button")
                onClicked: {
                    showVoiceMessageButton.value = !checked
                    showVoiceMessageButton.sync()
                }
            }

            TextSwitch {
                width: parent.width -2*x
                x:Theme.horizontalPageMargin
                checked: showCurrentTimeLabel.value
                automaticCheck: false
                text: qsTr("Show current time below message input")
                onClicked: {
                    showCurrentTimeLabel.value = !checked
                    showCurrentTimeLabel.sync()
                }
            }

            ExpandingSectionGroup {
                width: parent.width
                ExpandingSection {
                    id: section
                    width: parent.width
                    title: qsTr("Night Mode")

                    content.sourceComponent: Column {
                        width: section.width -2*x
                        x:Theme.horizontalPageMargin

                        TextSwitch {
                            width: parent.width
                            checked: nightMode.value
                            automaticCheck: false
                            enabled: !nightScheduleSwitch.checked
                            text: qsTr("Enable night mode")
                            onClicked: {
                                nightMode.value = !checked
                                nightMode.sync()
                            }
                        }
                        TextSwitch {
                            id:nightScheduleSwitch
                            width: parent.width
                            checked: nightModeSchedule.value
                            automaticCheck: false
                            text: qsTr("Enable schedule")
                            onClicked: {
                                nightModeSchedule.value = !checked
                                nightModeSchedule.sync()
                            }
                        }

                        Row {
                            width: section.width
                            ValueButton {
                                function openTimeDialog() {
                                    var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                                                    hourMode: DateTime.TwentyFourHours
                                                                })

                                    dialog.accepted.connect(function() {
                                        nightModeFrom.value = dialog.time
                                        nightModeFrom.sync()
                                    })
                                }

                                label: qsTr("From")
                                value: Format.formatDate(nightModeFrom.value, Formatter.TimeValue)
                                width: parent.width / 2
                                onClicked: openTimeDialog()
                            }
                            ValueButton {
                                function openTimeDialog() {
                                    var dialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                                                                    hourMode: DateTime.TwentyFourHours
                                                                })

                                    dialog.accepted.connect(function() {
                                        nightModeTill.value = dialog.time
                                        nightModeTill.sync()
                                    })
                                }

                                label:qsTr("Till")
                                value: Format.formatDate(nightModeTill.value, Formatter.TimeValue)
                                width: parent.width / 2
                                onClicked: openTimeDialog()
                            }
                        }
                    }
                }
            }
            Button {
                width: Theme.buttonWidthMedium
                text:qsTr("Reset to default")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    settingsUIMessage.radius = 0
                    settingsUIMessage.opacity = 0
                    settingsUIMessage.color = 1
                    settingsUIMessage.incomingColor = 5
                    settingsUIMessage.oneAligning = false
                    settingsUIMessage.fullSizeInChannels = false
                    settingsUI.hideNameplate = false

                    nightModeTill.value = nightModeTill.defaultValue
                    nightModeFrom.value = nightModeFrom.defaultValue
                    nightMode.value = nightMode.defaultValue
                    nightModeSchedule.value = nightModeSchedule.defaultValue
                    radiusSlider.value = settingsUIMessage.radius
                    opacitySlider.value = settingsUIMessage.opacity
                }
            }
        }
    }
}

