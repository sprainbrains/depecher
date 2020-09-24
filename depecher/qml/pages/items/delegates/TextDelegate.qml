import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import tdlibQtEnums 1.0
import "utils.js" as JsUtils

Column {
    id:textColumn
    width: textItem.width

    states: [
        State {
            name: "fullSizeWithMarginCorrection"
            when: settingsUIMessage.fullSizeInChannels && messagingModel.chatType["is_channel"]
            PropertyChanges {
                target: textItem
                width: JsUtils.getWidth() - 2 * textColumn.x
            }
            PropertyChanges {
                target: textColumn
                x: Theme.paddingMedium
                width: JsUtils.getWidth()
            }
        }
    ]

    RichTextItem {
        id: textItem
        width: messageListItem.width * 2 / 3 - Theme.horizontalPageMargin * 2
        content:  rich_text
    }
}
