import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0

Image {
    id: stickerImage
    asynchronous: true
    // FIXME
    width: {
        if (model.is_animated_sticker) {
            if (settingsUIMessage.scaleUpAnimatedStickerThumbnail)
                return 128 * 2
            else
                return 128
        }
        else
            return (Theme.itemSizeHuge * 1.3)
    }
    height: width
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    source: content ? "image://depecherDb/" + content : ""
    MouseArea {
        anchors.fill: parent
        onClicked: {
            pageStack.push(Qt.resolvedUrl("../../components/PreviewStickerSetDialog.qml"),{
                               set_id: sticker_set_id,
                               is_animated_sticker: model.is_animated_sticker
                           })
        }
    }
}


