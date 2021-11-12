import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0
import QtMultimedia 5.6
import QtQml.Models 2.3
import "utils.js" as JsUtils

Column{
    id:gifColumn
        width:animation.width
        property alias textHeight: captionText.height
        property real currentWidth: JsUtils.getWidth()
        property real currentHeight: JsUtils.getHeight() - nameplateHeight
        property bool marginCorrection: currentWidth < currentHeight*photo_aspect ||
                                        currentHeight*photo_aspect > currentWidth - Theme.horizontalPageMargin + 10
        states: [
            State {
                name: "fullSize"
                when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                      !marginCorrection
            }, State {
                name: "fullSizeWithMarginCorrection"
                extend: "fullSize"
                when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                      marginCorrection
                PropertyChanges {
                    target: captionText
                    x: Theme.paddingMedium
                    width: animation.width - 2 * x
                }

            }
        ]

        Component {
            id:gifComponent
            AnimatedImage {
                id:animationGif
                property int maxWidth:JsUtils.getWidth()-Theme.itemSizeExtraSmall - Theme.paddingMedium - 2*Theme.horizontalPageMargin
                property int maxHeight: JsUtils.getHeight() / 2
                width: media_preview ? (photo_aspect > 1 ? maxWidth : maxHeight * photo_aspect) : Theme.itemSizeExtraLarge
                height: media_preview ? (photo_aspect > 1 ? maxWidth/photo_aspect : maxHeight) : Theme.itemSizeExtraLarge
                fillMode: VideoOutput.PreserveAspectFit
                source: file_downloading_completed ? "file://"+content : ""
                playing: false
                asynchronous: true
                Image {
                    id:animationThumbnail
                    anchors.fill: parent
                    sourceSize.width: width
                    sourceSize.height: height
                    source: media_preview ? ("image://depecherDb/" + media_preview) : ""
                    visible:  mediaPlayer.playbackState != MediaPlayer.PlayingState || !file_downloading_completed;
                    asynchronous: true

                    Rectangle {
                        id:dimmedColor
                        anchors.fill: parent
                        opacity: 0.5
                        color:"black"
                    }
                    ProgressCircle {
                        id:progress
                        anchors.centerIn: parent
                        
                        visible: file_is_uploading || file_is_downloading
                        value : file_is_uploading ? file_uploaded_size / file_downloaded_size :
                                                    file_downloaded_size / file_uploaded_size
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

                    Label {
                        color:  Theme.primaryColor
                        visible: downloadIcon.visible
                        font.pixelSize: Theme.fontSizeTiny
                        text: Format.formatFileSize(file_downloaded_size) + "/"
                              + Format.formatFileSize(file_uploaded_size)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: Theme.paddingSmall
                        anchors.bottomMargin: Theme.paddingSmall
                    }
                }
                Rectangle {
                    id:dimmedPlayColor
                    anchors.fill: animation
                    opacity: 0.5
                    color:"black"
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                    
                }
                Image {
                    id: playIcon
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                    source:  "image://theme/icon-m-play"
                    anchors.centerIn: dimmedPlayColor
                }
                MouseArea{
                    anchors.fill: dimmedPlayColor
                    enabled: file_downloading_completed
                    onClicked: {
                        animationGif.playing = !animationGif.playing
                    }
                    Connections {
                        target: Qt.application
                        onStateChanged: {
                            if(Qt.application.state !== Qt.ApplicationActive)
                                nimationGif.playing = false
                        }
                    }
                    
                }
                states: [
                    State {
                        name: "fullSize"
                        when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                              !marginCorrection
                        PropertyChanges {
                            target: animationGif
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
                    }
                ]
            }
        }
        Component {
            id:mp4Component
            VideoOutput {
                id: animationVideo
                property int maxWidth: JsUtils.getWidth() - Theme.itemSizeExtraSmall - Theme.paddingMedium - 2*Theme.horizontalPageMargin
                property int maxHeight: JsUtils.getHeight() / 2
                width: media_preview ? (photo_aspect > 1 ? maxWidth : maxHeight * photo_aspect) : Theme.itemSizeExtraLarge
                height: media_preview ? (photo_aspect > 1 ? maxWidth / photo_aspect : maxHeight) : Theme.itemSizeExtraLarge
                fillMode: VideoOutput.PreserveAspectFit
                
                source: MediaPlayer {
                    id: mediaPlayer
                    source: file_downloading_completed ? "file://"+(content) : ""
                    autoLoad: true
                    // autoPlay: true
                    loops:  Animation.Infinite
                }
                Connections {
                    target: Qt.application
                    onStateChanged: {
                        if(Qt.application.state !== Qt.ApplicationActive)
                            mediaPlayer.stop()
                    }
                }
                
                Image {
                    id:animationThumbnail
                    anchors.fill: parent
                    sourceSize.width: width
                    sourceSize.height: height
                    source: media_preview ? ("image://depecherDb/" + media_preview) : ""
                    visible:  mediaPlayer.playbackState != MediaPlayer.PlayingState || !file_downloading_completed;
                    asynchronous: true

                    Rectangle {
                        id:dimmedColor
                        anchors.fill: parent
                        opacity: 0.5
                        color:"black"
                    }
                    ProgressCircle {
                        id:progress
                        anchors.centerIn: parent
                        
                        visible: file_is_uploading || file_is_downloading
                        value : file_is_uploading ? file_uploaded_size / file_downloaded_size :
                                                    file_downloaded_size / file_uploaded_size
                    }
                    IconButton {
                        id: downloadIcon
                        visible: !!media_preview && (!file_downloading_completed || progress.visible)
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

                    Label {
                        color:  Theme.primaryColor
                        visible: downloadIcon.visible
                        font.pixelSize: Theme.fontSizeTiny
                        text: Format.formatFileSize(file_downloaded_size) + "/"
                              + Format.formatFileSize(file_uploaded_size)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: Theme.paddingSmall
                        anchors.bottomMargin: Theme.paddingSmall
                    }
                }
                Rectangle {
                    id:dimmedPlayColor
                    anchors.fill: animationVideo
                    opacity: 0.5
                    color:"black"
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                }
                Image {
                    id: playIcon
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                    source:  "image://theme/icon-m-play"
                    anchors.centerIn: dimmedPlayColor
                }
                MouseArea {
                    anchors.fill: dimmedPlayColor
                    enabled: file_downloading_completed
                    onClicked: {
                        mediaPlayer.playbackState != MediaPlayer.PlayingState ?   mediaPlayer.play() : mediaPlayer.stop()
                    }
                }
                states: [
                    State {
                        name: "fullSize"
                        when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"] &&
                              !marginCorrection
                        PropertyChanges {
                            target: animationVideo
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
                    }
                ]

            }
        }
        Loader {
            id:animation
            sourceComponent: file_type === "video/mp4" ? mp4Component : gifComponent
        }
        RichTextItem {
            id:captionText
            width: parent.width
            content:  rich_file_caption
            visible:  file_caption === "" ? false : true
        }


    }
