import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Item {
    property alias settingsBehavior: settingsBehavior
    property alias settingsUI: settingsUI
    property alias settingsUIMessage: settingsUIMessage

    property string settingsPath: "/apps/depecher/"

    ConfigurationGroup {
        id: settingsBehavior
        path: settingsPath + "behavior"
        property bool sendByEnter: false
    }

    ConfigurationGroup {
        id: settingsUI
        path: settingsPath + "ui"
        property bool hideNameplate : false

        ConfigurationGroup {
            id: settingsUIMessage
            path: "message"
            property int radius: 0
            property real opacity: 0
            property int color: 1 //Theme.secondaryColor
            property int incomingColor: 5 //Theme.highlightDimmerColor
            property int timepoint: Formatter.Timepoint
            property bool oneAligning: false
            property bool fullSizeInChannels: false
        }
    }
}
