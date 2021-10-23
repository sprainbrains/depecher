import QtQuick 2.6
import Sailfish.Silica 1.0
import tdlibQtEnums 1.0
import TelegramModels 1.0
import "items"
import "components"

Page {
    id: page
    property string titleHeader: "Depecher"
    property string _opened_chat_id: ""

    function openAuthorizeDialog() {
        pageStack.completeAnimation()
        pageStack.replace(Qt.resolvedUrl("AuthorizeDialog.qml"),{},PageStackAction.Immediate)
    }

    Connections {
        target: c_telegramWrapper
        onErrorReceivedMap: {
            if (errorObject["code"] === 401)
                openAuthorizeDialog()
        }
        onAuthorizationStateChanged: {
            // Phone can be already set in some cases
            if (c_telegramWrapper.authorizationState === TdlibState.AuthorizationStateWaitPhoneNumber ||
                c_telegramWrapper.authorizationState === TdlibState.AuthorizationStateWaitCode)
                openAuthorizeDialog()
        }
    }

    property bool pageLoaded: false
    onStatusChanged: {
        if (!pageLoaded && (page.status == PageStatus.Active)) {
            pageLoaded = true
            if (c_telegramWrapper.authorizationState === TdlibState.AuthorizationStateWaitPhoneNumber ||
                c_telegramWrapper.authorizationState === TdlibState.AuthorizationStateWaitCode)
                openAuthorizeDialog()
        }
    }

    Connections {
        target: c_joinManager
        onInviteLinkReady: {
            pageStack.push(Qt.resolvedUrl("JoinChatDialog.qml"), { title: title, link: link })
        }
        // FIXME: open chat instead
        onInviteIdReady: {
            pageStack.push(Qt.resolvedUrl("JoinChatDialog.qml"), { title: title, chatId: chatId })
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        currentIndex: -1
        model: FilterChatsModel {
            id: filterChatsModel
            sourceModel: ChatsModel {
                id: chatsModel
            }
        }

        PullDownMenu {
            busy: c_telegramWrapper.connectionState !== TdlibState.ConnectionStateReady
            MenuItem {
                text:qsTr("Reset dialogs")
                onClicked: chatsModel.reset()
            }
            MenuItem {
                text:qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text:qsTr("Contacts")
                onClicked: pageStack.push(Qt.resolvedUrl("ContactsPage.qml"))
            }
            MenuItem {
                text: listView.searchField.active ? qsTr("Hide Search") : qsTr("Search")
                onDelayedClick: listView.searchField.active = !listView.searchField.active
            }
        }

        property SearchField searchField: null

        header:  PageHeader {
            title: titleHeader
            SearchField {
                id: searchField
                width: parent.width - parent._titleItem.width - (isLandscape ? Theme.paddingMedium*2 : 0)
                anchors {
                    verticalCenter: parent.verticalCenter //parent._titleItem.verticalCenter
                    left: parent.left
                    leftMargin: isLandscape ? Theme.paddingMedium : 0
                }
                placeholderText: qsTr("Search")
                inputMethodHints: Qt.ImhNoAutoUppercase
                focusOutBehavior: FocusBehavior.ClearItemFocus
                autoScrollEnabled: false
                active: false
                canHide: true

                Component.onCompleted: listView.searchField = searchField
                onTextChanged: filterChatsModel.search = text
                onHideClicked: active = false
                onActiveChanged: {
                    if (active)
                        forceActiveFocus()
                }
            }
        }

        delegate: ChatItem {
            id: chatDelegate
            activeChat: _opened_chat_id === model.id

            menu:  ContextMenu {
                MenuItem {
                    text: mute_for > 0 ? qsTr("Unmute") : qsTr("Mute")
                    onClicked: chatsModel.changeNotificationSettings(id,!(mute_for > 0))
                }
                MenuItem {
                    property bool unread: (is_marked_unread || unread_count)
                    text: unread ? qsTr("Mark as read") : qsTr("Mark as unread")
                    onClicked: chatsModel.markAsUnread(id, !unread)
                }
                MenuItem {
                    text: wantDelete ? qsTr("Remove history and leave chat") : qsTr("Leave chat")
                    property bool wantDelete: type["type"] == TdlibState.Private ||
                                              type["type"] == TdlibState.BasicGroup ||
                                              type["type"] == TdlibState.Secret
                    onClicked: {
                        chatDelegate.remorseAction(qsTr("Left chat"), function () {
                            if (wantDelete)
                                c_telegramWrapper.deleteChatHistory(id, true)
                            else
                                c_telegramWrapper.leaveChat(id)

                            if (page.canNavigateForward && _opened_chat_id === id)
                                pageStack.popAttached(page, PageStackAction.Immediate)
                        })
                    }
                }
            }

            ListView.onAdd: AddAnimation {
                target: chatDelegate
            }

            ListView.onRemove: RemoveAnimation {
                target: chatDelegate
            }

            onClicked: {
                if (_opened_chat_id !== model.id || !page.canNavigateForward) {
                    _opened_chat_id = model.id
                    if (is_marked_unread)
                        chatsModel.markAsUnread(model.id, false)
                    pageStack.pushAttached("MessagingPage.qml",{chatId:model.id})
                }

                pageStack.navigateForward()
            }
        }

        VerticalScrollDecorator {
            flickable: listView
        }
    }

    Component.onCompleted: app.chatsPage = page
}
