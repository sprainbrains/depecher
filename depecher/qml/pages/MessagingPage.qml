import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramModels 1.0
import QtFeedback 5.0
import tdlibQtEnums 1.0
import depecherUtils 1.0
import Nemo.Notifications 1.0
import Nemo.Configuration 1.0
import "../js/utils.js" as Utils
import "items"
Page {
    id: page
    property alias nameplateHeight: nameplate.height
    property alias chatId: messagingModel.peerId
    property var forwardMessages: ({})
    property var arrayIndex: []
    property FilterChatMembersModel filterChatMembersModel: null
    property bool infoPageLoaded: false

    onStatusChanged: {
        if (!infoPageLoaded && status == PageStatus.Active) {
            infoPageLoaded = true
            if(messagingModel.chatType["type"] == TdlibState.BasicGroup) {
                var infoPage = pageStack.pushAttached(Qt.resolvedUrl("GroupInfoPage.qml"),{chat_id:parseFloat(chatId)})
                infoPage.filterChatMembersModelChanged.connect(function (membersModel) {
                    page.filterChatMembersModel = membersModel
                })
            } else if (messagingModel.chatType["type"] == TdlibState.Secret || messagingModel.chatType["type"] == TdlibState.Private) {
                pageStack.pushAttached(Qt.resolvedUrl("UserPage.qml"),{user_id:parseInt(chatId)})
            } else if (messagingModel.chatType["type"] == TdlibState.Supergroup) {// && messagingModel.chatType["is_channel"])
                var userPage = pageStack.pushAttached(Qt.resolvedUrl("UserPage.qml"),{chat_id:parseFloat(chatId),hideOpenMenu:true})
                userPage.filterChatMembersModelChanged.connect(function (membersModel) {
                    page.filterChatMembersModel = membersModel
                })
            }
        } else if (status == PageStatus.Inactive) {
            if (filterChatMembersModel) {
                writer.textArea.state = "text"
                writer.textArea.searchMemberStr = ""
                writer.textArea.searchMemberStrPos = -1
                filterChatMembersModel.search = ""
            }
        }
    }

    Notification {
        id: notificationError
        appName: "Depecher"
        expireTimeout: 1
    }

    MsgPageSettings {
        id: msgPageSettings
    }
    property alias settingsBehavior: msgPageSettings.settingsBehavior
    property alias settingsUI: msgPageSettings.settingsUI
    property alias settingsUIMessage: msgPageSettings.settingsUIMessage

    MessagingModel{
        id: messagingModel
        isActive: page.status === PageStatus.Active && Qt.application.active
        onChatTypeChanged: {
            if(chatType["type"] == TdlibState.Supergroup)
            {
                if(!canPostMessages(memberStatus)) {
                    writer.sendAreaHeight = 0
                    writer.bottomArea.visible = false
                }
            }
        }
        function canPostMessages(statusObj) {
            if(messagingModel.chatType["type"] == TdlibState.Supergroup) {
                if(messagingModel.chatType["is_channel"])
                {
                    if(statusObj["status"] == MessagingModel.Member)
                        return false;
                    if(statusObj["status"] == MessagingModel.Creator && statusObj["is_member"])
                        return true;
                    if(statusObj["status"] == MessagingModel.Administrator)
                        return statusObj["can_post_messages"];
                }

                return true;
            }
            return true;
        }
        onCallbackQueryAnswerShow: {
            notificationError.previewBody = text
            if(show_alert)
                notificationError.icon = "image://theme/icon-lock-warning"
            else
                notificationError.icon = "image://theme/icon-lock-information"
            notificationError.publish()
        }
        onErrorReceived: {
            notificationError.previewBody = error_code +"-" +error_message
            notificationError.icon = "image://theme/icon-lock-warning"

            notificationError.publish()
        }
    }
    Component.onCompleted: {
        if (Object.keys(forwardMessages).length !== 0) {
            writer.reply_id = "-1"
            writer.replyMessageAuthor = qsTr("Forwarded messages")
            writer.replyMessageText = forwardMessages.messages.length + " " + qsTr("messages")
        }
        c_telegramWrapper.openChat(messagingModel.peerId)
    }
    Component.onDestruction: {
        c_telegramWrapper.closeChat(messagingModel.peerId)
    }

    ThemeEffect {
        id: buzz
        effect: ThemeEffect.Press
    }

    WritingItem {
        id: writer
        rootPage: page
        anchors.fill: parent

        Timer {
            //Because TextBase of TextArea uses Timer for losing focus.
            //Let's reuse that =)
            id: restoreFocusTimer
            interval: 50
            onTriggered: writer.textArea.forceActiveFocus()
        }

        KeysEater {
            target: keys.length ? writer.textArea._editor : null
            keys: {
                if (writer.textArea.state === "searchMember" && writer.chatMembersList.count)
                    return [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Up, Qt.Key_Down]
                else
                    return settingsBehavior.sendByEnter ? [Qt.Key_Return, Qt.Key_Enter] : []
            }

            onKeyPressed: {
                switch (key) {
                case Qt.Key_Up:
                    writer.chatMembersList.currentIndex = Math.max(writer.chatMembersList.currentIndex - 1, 0)
                    break
                case Qt.Key_Down:
                    writer.chatMembersList.currentIndex = Math.min(writer.chatMembersList.currentIndex + 1, writer.chatMembersList.count - 1)
                    break
                }
            }
        }

        EnterKey.iconSource: settingsBehavior.sendByEnter ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter"
        EnterKey.onClicked: {
            if (textArea.state === "searchMember" && chatMembersList.currentIndex >= 0) {
                var targetCursorPos
                var sourceIndex = filterChatMembersModel.sourceIndex(chatMembersList.currentIndex)
                var username = filterChatMembersModel.sourceModel.getProperty(sourceIndex, "username")
                if (username.length) {
                    targetCursorPos = textArea.searchMemberStrPos + username.length + 2
                    textArea.text = text.substring(0, textArea.searchMemberStrPos) + "@" + username + " " + text.substring(textArea.cursorPosition)
                } else {
                    var name = filterChatMembersModel.sourceModel.getProperty(sourceIndex, "name")
                    targetCursorPos = textArea.searchMemberStrPos + name.length + 1
                    textArea.text = text.substring(0, textArea.searchMemberStrPos) + name + " " + text.substring(textArea.cursorPosition)
                }
                textArea.cursorPosition = targetCursorPos
                chatMembersList.currentIndex = -1
            } else if (settingsBehavior.sendByEnter) {
                sendText(textArea.text, writer.reply_id)
            }
        }
        Keys.onUpPressed: {
            var listItems=messageList.contentItem.children
            for (var i=0; i<listItems.length; ++i){
                if (listItems[i].currentMessageType !== undefined) {
                    if (listItems[i].messageEditable) {
                        listItems[i].triggerEdit()
                        // break;   // break here if you want to edit even if someone answered.
                        // If the list is scrolling, children change index while looping,
                        // and it ends up peaking the wrong child.
                        // Is there any porperty that tells whether it is scrolling?
                    }
                    break;
                }
            }
        }

        returnButtonItem.onClicked: {
            if(arrayIndex.length > 0) {
                messageList.currentIndex = arrayIndex.pop()
                messageList.positionViewAtIndex(messageList.currentIndex,ListView.Center)
            }
            returnButtonEnabled = arrayIndex.length > 0
        }
        actionButton.onClicked:  {
            sendText(textArea.text,writer.reply_id)
        }
        onSendVoice: {
            messagingModel.sendVoiceMessage(location,duration,writer.reply_id, "",waveform)
            writer.clearReplyArea()
        }
        onSendFiles: {
            for(var i = 0; i < files.length; i++)
            {
                var fileUrl = String(files[i].url)
                if(fileUrl.slice(0,4) === "file")
                    fileUrl = fileUrl.slice(7, fileUrl.length)
                //Slicing removes occurance of file://
                if(files[i].type === TdlibState.Photo)
                    messagingModel.sendPhotoMessage(fileUrl, writer.reply_id, "")
                if(files[i].type === TdlibState.Document)
                    messagingModel.sendDocumentMessage(fileUrl,writer.reply_id,"")
                if(files[i].type === TdlibState.Sticker)
                    messagingModel.sendStickerMessage(files[i].id,writer.reply_id)
            }
            writer.clearReplyArea()

        }
        onReplyAreaCleared: forwardMessages = {}

        BusyIndicator {
            id:placeholder
            running: true
            size: BusyIndicatorSize.Large
            anchors.centerIn: messageList.parent
        }
        Column {
            width: page.width
//            height: parent.height - writer.sendAreaHeight
            anchors.top:parent.top
            anchors.bottom:parent.bottom
            anchors.bottomMargin: writer.sendAreaHeight
            PageHeader {
                id: nameplate
                title: settingsUI.hideNameplate ? "" : messagingModel.userName
                height: settingsUI.hideNameplate ? actionLabel.height + Theme.paddingMedium : Math.max(_preferredHeight, _titleItem.y + _titleItem.height + actionLabel.height  + Theme.paddingMedium)
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
                id: messageList
                property bool needToScroll: false
                width: parent.width
                height: parent.height - nameplate.height
                signal showDateSection()
                signal hideDateSection()

                onMovementStarted: showDateSection()
                onMovementEnded: hideDateSection()

                clip: true
                spacing: Theme.paddingSmall
                model: messagingModel

                // hide dummy items
                topMargin: messagingModel.dummyCnt * -(Theme.itemSizeExtraLarge + 15 + spacing) // 15: spacing in columnWrapper

                onHeightChanged: {
                    if (messageList.indexAt(width/2,height+contentY) >= count - 2)
                        messageList.positionViewAtEnd()
                }

                VerticalScrollDecorator {
                    flickable: messageList
                    _headerSpacing: messageList.topMargin
                }

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: messagingModel.fetching ||
                             (fetchOlderTimer.running && messageList.state == "ready")
                }

                state: "preparing"
                states: [
                    State {
                        name: "preparing"
                        PropertyChanges {
                            target: placeholder
                            running:true
                        }
                        PropertyChanges {
                            target: messageList
                            visible:false
                        }
                    }, State {
                        name: "ready"
                        PropertyChanges {
                            target: placeholder
                            running:false
                        }
                        PropertyChanges {
                            target: messageList
                            visible:true
                        }
                    }
                ]
                section {
                    id: dateSection
                    property: "section"
                    labelPositioning: ViewSection.InlineLabels
                    delegate: Label {
                        id:secLabel
                        wrapMode: Text.WordWrap
                        color:Theme.highlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        text: Utils.formatDate(section, true)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: Theme.paddingMedium

                        MouseArea {
                            anchors.fill: parent
                            onClicked:{
                                // TODO: move to the 1st message for the section
                            }
                        }
                        Timer {
                            id: changeToInlineLabelsTimer
                            interval: 1500
                            onTriggered: {
                                if (!messageList.moving) {
                                    dateSection.labelPositioning = ViewSection.InlineLabels
                                }
                            }
                        }
                        Connections {
                            target: messageList
                            onShowDateSection: {
                                dateSection.labelPositioning = ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
                            }
                            onHideDateSection: {
                                changeToInlineLabelsTimer.start()
                            }
                        }
                    }
                }

                NumberAnimation {
                    id:moveAnimation
                    target: messageList
                    property: "contentY"
                    duration: 500
                    easing.type: Easing.InOutQuad
                    running: false
                    onRunningChanged: {
                        if(!running)
                            fetchOlder()
                    }
                }
                boundsBehavior: Flickable.DragOverBounds

                Connections {
                    target: messagingModel
                    onRowsInserted: {
                        if (first == 0) {
                            for(var i = 0; i < arrayIndex.length; i++)
                                arrayIndex[i] = arrayIndex[i] + last + 1
                        }
                        if (messageList.atYEnd && messageList.state !== "preparing")
                            positionAtEndTimer.start()
                    }
                }

                onContentYChanged: {
                    if (!messagingModel.fetching &&
                       atYBeginning && !messagingModel.reachedHistoryEnd)
                    {
                        fetchOlderTimer.start()
                    }
//                    needToScroll = indexAt(messageList.width/2,contentY + 50) > messageList.count - 8
                }

                Timer {
                    id:fetchOlderTimer
                    interval: 500
                    repeat: false
                    onTriggered:{
                        if (messageList.state == "ready")
                            fetchOlder()
                    }
                }

                Timer {
                    id:positionAtEndTimer
                    interval: 500
                    repeat: false
                    onTriggered: messageList.positionViewAtEnd()
                }

                Timer {
                    id:centerTimer
                    interval: 800
                    onTriggered: {
                        var i = messagingModel.lastMessageIndex + messagingModel.dummyCnt
                        messageList.positionViewAtIndex(i, ListView.Beginning)
                        messageList.currentIndex = i
                        if (messageList.count <= 10) {
                            fetchOlder()
                            stateReadyTimer.start()
                        } else {
                            // Model already filled, skip initial fetching
                            messageList.state = "ready"
                        }

                    }
                }

                Timer {
                    id: stateReadyTimer
                    interval: 100
                    onTriggered: messageList.state = "ready"
                }

                Component.onCompleted: centerTimer.start()

                delegate: MessageItem {
                    id: myDelegate
                    menu: index >= messagingModel.dummyCnt ? contextMenu : undefined
                    onReplyMessageClicked:    {
                        if (messagingModel.findIndexById(replied_message_index) !== -1) {
                            arrayIndex.push(source_message_index)
                            writer.returnButtonEnabled = true
                            var i = messagingModel.findIndexById(replied_message_index) + messagingModel.dummyCnt

                            // delegate might be deleted here so messageList will be undefined
                            var _messageList = messageList
                            _messageList.positionViewAtIndex(i, ListView.Center)
                            _messageList.currentIndex = i
                        }/* else {
                            messagingModel.loadAndRefreshRepliedByIndex(source_message_index)
                        }*/
                    }

                    property bool messageEditable: {
                        return typeof can_be_edited !== "undefined" &&
                                can_be_edited && (model.message_type === MessagingModel.TEXT
                                                  || model.message_type === MessagingModel.PHOTO
                                                  || model.message_type === MessagingModel.VIDEO
                                                  || model.message_type === MessagingModel.DOCUMENT
                                                  || model.message_type === MessagingModel.ANIMATION
                                                  || model.message_type === MessagingModel.VOICE
                                                  || model.message_type === MessagingModel.AUDIO)
                    }
                    signal triggerEdit()
                    onTriggerEdit: editEntry.clicked()

                    onRealDoubleClicked: {
                        // TODO add settings?
                        if  ((messagingModel.chatType["type"] == TdlibState.Supergroup && !messagingModel.chatType["is_channel"]) ||
                              messagingModel.chatType["type"] == TdlibState.BasicGroup ||
                              messagingModel.chatType["type"] == TdlibState.Private)
                        {
                            writer.reply_id = id
                            writer.replyMessageAuthor = author
                            writer.replyMessageText = replyMessageContent()
                        }
                    }

                    Component {
                        id: contextMenu
                        ContextMenu {
                            MenuItem {
                                text: qsTr("Reply")
                                visible:  ((messagingModel.chatType["type"] == TdlibState.Supergroup && !messagingModel.chatType["is_channel"]) ||
                                           messagingModel.chatType["type"] == TdlibState.BasicGroup ||
                                           messagingModel.chatType["type"] == TdlibState.Private)
                                onClicked: {
                                    writer.reply_id = id
                                    writer.replyMessageAuthor = author
                                    writer.replyMessageText = myDelegate.replyMessageContent()
                                }
                            }
                            MenuItem {
                                id: editEntry
                                text:qsTr("Edit")
                                visible: myDelegate.messageEditable

                                onClicked: {
                                    if(message_type == MessagingModel.TEXT)
                                        writer.state = "editText"
                                    else
                                        writer.state = "editCaption"

                                    writer.edit_message_id = id
                                    writer.replyMessageText = myDelegate.replyMessageContent()
                                    writer.text = message_type == MessagingModel.TEXT ? content : file_caption
                                    writer.textArea.focus = true
                                    writer.textArea.cursorPosition = writer.text.length
                                }
                            }
                            MenuItem {
                                text: qsTr("Forward")
                                visible: typeof can_be_forwarded !== "undefined" &&
                                         can_be_forwarded && !writer.textArea.activeFocus
                                onClicked: {
                                    pageStack.push("SelectChatDialog.qml",{"from_chat_id": chatId,
                                                       "messages": [id]})
                                }
                            }
                            MenuItem {
                                text:message_type == MessagingModel.TEXT || file_caption ? qsTr("Copy text") : qsTr("Copy path")
                                onClicked: {
                                    if(message_type == MessagingModel.TEXT)
                                        Clipboard.text = content
                                    else if (file_caption)
                                        Clipboard.text = file_caption
                                    else
                                        Clipboard.text = content
                                }
                            }
                            MenuItem {
                                text: qsTr("Delete Message")
                                visible: can_be_deleted_only_for_yourself && !writer.textArea.activeFocus ? can_be_deleted_only_for_yourself : false
                                onClicked: {
                                    showRemorseDelete(false)
                                }
                            }
                            MenuItem {
                                text: qsTr("Delete for everyone")
                                visible: can_be_deleted_for_all_users && !writer.textArea.activeFocus ? can_be_deleted_for_all_users : false
                                onClicked: {
                                    showRemorseDelete(true)
                                }
                            }

                            function showRemorseDelete(forEveryone) {
                                // index and messagingModel are not available in RemorseItem context
                                var _index = index
                                var _messagingModel = messagingModel
                                myDelegate.remorseAction(qsTr("Deleting..."), function() {
                                    _messagingModel.deleteMessage(_index, forEveryone)
                                })
                            }
                        }
                    }

                    function replyMessageContent() {
                        switch (message_type) {
                        case MessagingModel.TEXT: return content
                        case MessagingModel.PHOTO: return qsTr("Photo")
                        case MessagingModel.STICKER: return qsTr("Sticker")
                        case MessagingModel.DOCUMENT: return qsTr("Document")
                        case MessagingModel.ANIMATION: return qsTr("Animation")
                        case MessagingModel.CONTACT:  return qsTr("Contact")
                        }
                        return qsTr("Message")
                    }
                }
            }
        }

        function sendText(text,reply_id) {
            Qt.inputMethod.commit()
            if(writer.state == "publish"){
                if(text.trim().length > 0)
                    messagingModel.sendTextMessage(text,reply_id)
                if(reply_id == -1)
                    messagingModel.sendForwardMessages(chatId,forwardMessages.from_chat_id,forwardMessages.messages)
            } else if (writer.state == "editText") {
                messagingModel.sendEditTextMessage(writer.edit_message_id,text)
            } else if (writer.state == "editCaption") {
                messagingModel.sendEditCaptionMessage(writer.edit_message_id,text)
            }

            buzz.play()
            textArea.text = ""
            restoreFocusTimer.start()
            clearReplyArea()
        }
    }

    Timer {
        id: fetchOlderRepeatTimer
        interval: 2000
    }

    function fetchOlder() {
        if (!messagingModel.fetching && !fetchOlderRepeatTimer.running) {
            messagingModel.fetchOlder()
            fetchOlderRepeatTimer.start()
        }
    }
}

