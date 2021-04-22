import QtQuick 2.6
import Sailfish.Silica 1.0
import tdlibQtEnums 1.0
import TelegramModels 1.0
import "items"
import "components"

Page {
    id: page

    property string titleHeader: "Depecher"
    //for search in pageStack
    property bool __chat_page: true
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
            if (c_telegramWrapper.authorizationState == TdlibState.AuthorizationStateWaitPhoneNumber)
                openAuthorizeDialog()
        }
    }

    property bool pageLoaded: false
    onStatusChanged: {
        if (!pageLoaded && (page.status == PageStatus.Active)) {
            pageLoaded = true
            if (c_telegramWrapper.authorizationState == TdlibState.AuthorizationStateWaitPhoneNumber)
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
        model: ChatsModel {
            id: chatsModel
        }

        header:  PageHeader {
            title: titleHeader
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
        }

        delegate: ChatItem {
            id: chatDelegate

            menu:  ContextMenu {
                MenuItem {
                    text: mute_for > 0 ? qsTr("Unmute") : qsTr("Mute")
                    onClicked: chatsModel.changeNotificationSettings(id,!(mute_for > 0))
                }
                MenuItem {
                    text: is_marked_unread ? qsTr("Mark as read") : qsTr("Mark as unread")
                    onClicked: chatsModel.markAsUnread(id,!is_marked_unread)
                }
                MenuItem {
                    text: qsTr("Leave chat")
                    onClicked: {
                        chatDelegate.remorseAction(qsTr("Left chat"), function () {
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

            onClicked:{
                var page = pageStack.find(function (page) {
                    return page.__messaging_page !== undefined
                });
                if(_opened_chat_id !== id)
                {
                    _opened_chat_id = id
                    if(is_marked_unread)
                        chatsModel.markAsUnread(id,false)
                    pageStack.pushAttached("MessagingPage.qml",{chatId:id})
                }
                pageStack.navigateForward()
            }
        }

        VerticalScrollDecorator {
            flickable: listView
        }
    }

}


