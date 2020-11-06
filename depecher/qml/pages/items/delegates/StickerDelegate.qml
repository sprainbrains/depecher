import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0

Image {
    id:stickerImage
    asynchronous: true
    anchors.fill: parent
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    source: content ? "image://depecherDb/" + content : ""
    MouseArea {
        anchors.fill: parent
        onClicked: pageStack.push(Qt.resolvedUrl("../../components/PreviewStickerSetDialog.qml"),{set_id:sticker_set_id})
    }
}


