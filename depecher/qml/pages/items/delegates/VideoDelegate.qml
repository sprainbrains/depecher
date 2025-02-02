import QtQuick 2.0
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0
import QtQml.Models 2.3
import "utils.js" as JsUtils


Column{
    id:videoColumn
    width: image.width
    property alias textHeight: captionText.height
    property real currentWidth: JsUtils.getWidth()
    property real currentHeight: JsUtils.getHeight()
    property bool marginCorrection: currentWidth < currentHeight*photo_aspect ||
                                    currentHeight*photo_aspect > currentWidth - Theme.horizontalPageMargin + 10

    states: [
        State {
            name: "fullSize"
            when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                  !marginCorrection
            PropertyChanges {
                target: image
                maxWidth: currentWidth
                maxHeight: currentHeight
                width: Math.min(maxHeight * photo_aspect, maxWidth)
                height: Math.min(maxHeight, maxWidth / photo_aspect)
            }
        }, State {
            name: "fullSizeWithMarginCorrection"
            extend: "fullSize"
            when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                  marginCorrection
            PropertyChanges {
                target: captionText
                x: Theme.paddingMedium
                width: image.width - 2 * x
            }

        }
    ]

    Image {
        id: image
        asynchronous: true
        property int maxWidth: JsUtils.getWidth() - Theme.itemSizeExtraSmall - Theme.paddingMedium - 2*Theme.horizontalPageMargin
        property int maxHeight: JsUtils.getHeight()/2
        width: media_preview ? (photo_aspect >= 1 ? maxWidth : maxHeight * photo_aspect) : Theme.itemSizeExtraLarge
        height: media_preview ? (photo_aspect >= 1 ? maxWidth/photo_aspect : maxHeight) : Theme.itemSizeExtraLarge
        fillMode: Image.PreserveAspectFit
        sourceSize.width: width
        sourceSize.height: height
        source: media_preview ? ("image://depecherDb/" + media_preview) : ""

        MouseArea{
            anchors.fill: parent
            enabled: file_downloading_completed
            onClicked:{
                pageStack.push("../../VideoPage.qml",{source:content,thumbnail:media_preview})}
        }

        ProgressCircle {
            id: progress
            anchors.centerIn: parent
            visible: file_is_uploading || file_is_downloading
            value : file_is_uploading ? file_uploaded_size / file_downloaded_size :
                                        file_downloaded_size / file_uploaded_size
        }

        Label {
            id:durationText
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin:  Theme.paddingSmall
            anchors.bottomMargin: Theme.paddingSmall

            color: pressed ? Theme.primaryColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny
            text: Format.formatDuration(duration,Formatter.DurationShort)
            z:1
        }
        Rectangle {
            id:dimmedPlayColor
            anchors.fill: image
            opacity: 0.5
            color:"black"
            visible: file_downloading_completed
        }
        Image {
            id: playIcon
            visible: file_downloading_completed
            source:  "image://theme/icon-m-play"
            anchors.centerIn: dimmedPlayColor
        }
        Rectangle {
            width: durationText.width + Theme.paddingSmall
            height: durationText.height
            anchors.centerIn: durationText
            radius: 10
            color:Theme.rgba(Theme.secondaryHighlightColor,0.5)
            z:0
        }

        IconButton {
            id: downloadIcon
            visible: !file_downloading_completed || progress.visible
            icon.source: progress.visible ? "image://theme/icon-s-clear-opaque-cross"
                                          : "image://theme/icon-s-update"
            anchors.centerIn: parent
            width: Math.min(parent.width, Theme.itemSizeMedium)
            height: width

            onClicked: {
                if(progress.visible)
                    if(file_is_downloading)
                        messagingModel.cancelDownload(index)
                    else
                        messagingModel.deleteMessage(index)
                else
                    messagingModel.downloadDocument(index)
            }
        }
    }
    RichTextItem {
        id:captionText
        width: parent.width
        content:  rich_file_caption
        visible:  file_caption === "" ? false : true
    }
}
