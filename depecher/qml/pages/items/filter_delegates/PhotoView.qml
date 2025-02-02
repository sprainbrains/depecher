import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0

Page {
    id:page
    property alias chatId: itemsModel.peerId
    property alias filter: itemsModel.filter
    property alias totalCount: itemsModel.totalCount
    SearchChatMessagesModel {
        id: itemsModel
    }
    SilicaGridView {
        id:grid
        property var currentFilter
        property Item expandItem
        header: PageHeader {
            title: qsTr("Images")
        }
        anchors.fill: parent
        property real cellSize: Math.floor(width / columnCount)
        property int columnCount: Math.floor(width / Theme.itemSizeHuge)
        cellHeight: cellSize
        cellWidth: cellSize

        model: itemsModel

        delegate: BackgroundItem {
            id:thumbnail

            width: grid.cellSize
            height:isExpanded ? grid.contextMenu.height + grid.cellHeight : grid.cellHeight
            property bool isExpanded: grid.expandItem === thumbnail
            Item {
                id:wrapper
                width:grid.cellSize
                height:width
                Image {
                    source: content ? content : ""
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                    asynchronous: true
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            onClicked: {
                pageStack.push("../../PicturePage.qml",{imagePath:content})
            }
        }
    }
}
