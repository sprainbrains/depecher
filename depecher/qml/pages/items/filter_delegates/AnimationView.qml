import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import TelegramModels 1.0
import tdlibQtEnums 1.0
import "../../../js/utils.js" as Utils

Page {
    id:page
    property alias chatId: itemsModel.peerId
    property alias filter: itemsModel.filter
    property alias totalCount: itemsModel.totalCount
    // TODO use one mediaplayer for all delegates
    property int playingIdx: -1

    SearchChatMessagesModel {
        id: itemsModel
    }
    SilicaGridView {
        id:grid
        header: PageHeader {
            title: qsTr("Animations")
        }
        model:itemsModel
        anchors.fill: parent
        cellHeight: width/3
        cellWidth: width/3

        delegate: ListItem {
            width: grid.cellWidth
            contentHeight: width

            openMenuOnPressAndHold: file_downloading_completed
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Open externally"
                        onClicked: {
                            Qt.openUrlExternally("file://"+(content))
                        }
                    }
                }
            }

            onClicked: {
                if (!file_downloading_completed)
                    return

                if (mediaPlayer.playbackState != MediaPlayer.PlayingState) {
                    playingIdx = model.index
                    mediaPlayer.play()
                } else {
                    mediaPlayer.stop()
                }
            }

            VideoOutput {
                id: animationVideo
                width: parent.width
                height: width
                fillMode: VideoOutput.PreserveAspectFit

                source: MediaPlayer {
                    id: mediaPlayer
                    source: file_downloading_completed ? "file://"+(content) : ""
                    autoLoad: true
                    loops: Animation.Infinite
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
                    anchors.fill: animationVideo
                    sourceSize.width: width
                    sourceSize.height: height
                    source: media_preview ? ("image://depecherDb/" + media_preview) : ""
                    visible: mediaPlayer.playbackState != MediaPlayer.PlayingState || !file_downloading_completed;
                    fillMode: Image.PreserveAspectFit
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
                            if (file_is_downloading)
                                itemsModel.cancelDownload(index)
                            else
                                itemsModel.downloadDocument(index)
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
                    color: "black"
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                }
                Image {
                    id: playIcon
                    visible: file_downloading_completed && mediaPlayer.playbackState != MediaPlayer.PlayingState
                    source:  "image://theme/icon-m-play"
                    anchors.centerIn: dimmedPlayColor
                }
                Connections {
                    target: page
                    onPlayingIdxChanged: {
                        if (mediaPlayer.playbackState != MediaPlayer.StoppedState
                                && playingIdx >= 0 && playingIdx !== model.index) {
                            mediaPlayer.stop()
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {
            flickable: grid
        }
    }
}
