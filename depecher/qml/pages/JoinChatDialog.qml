import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: dialog
    property string link
    property string title
    property real chatId

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        DialogHeader {
            id: dialogHeader
            //: Join to channel
            defaultAcceptText: qsTr("Join")
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Join Channel: ")
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeLarge
            text: dialog.title
        }
    }

    onAccepted: {
        if (link.length)
            c_telegramWrapper.joinChatByInviteLink(link)
        else
            c_telegramWrapper.joinChat(chatId)
    }
}
