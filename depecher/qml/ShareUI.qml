/******************************************************************************
Copyright (c) 2014 - 2021 Jolla Ltd.
Copyright (c) 2021 Open Mobile Platform LLC.
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer. Redistributions in binary
    form must reproduce the above copyright notice, this list of conditions and
    the following disclaimer in the documentation and/or other materials
    provided with the distribution. Neither the name of the Jolla Ltd. nor
    the names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
******************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Share 1.0
import Sailfish.TransferEngine 1.0
import Nemo.DBus 2.0
import "pages/components"
import "org/blacksailer/depecher/sharechat" 1.0
import "js/mimetypes.js" as Mime

SilicaListView {
    id: listModel
    model: ShareChatModel {
        id: shareChatModel
    }
    clip: true
    height: Screen.height

    property var chat_ids: []
    property int chat_ids_length: 0
    property var resourcesMap: {"description": "Depecher"}
    property ShareAction shareAction: null // filled by SystemDialog.qml

    header: PageHeader {
        title: chat_ids_length == 0 ? qsTr("Choose chat") : qsTr("%1 selected").arg(chat_ids_length)
    }

    PullDownMenu {
        MenuItem {
            text: qsTr("Reset")
            onClicked: model.reset()
        }
        MenuItem {
            text: qsTr("Accept")
            enabled: chat_ids_length
            onClicked: {
                var source = shareItem.source
                var content = shareItem.content

                if (source == "" && content && 'type' in content) {
                    if (content.type === 'text/x-url') {
                        shareItem.notificationsEnabled = false
                        shareItem.userData = {
                            "recipients": chat_ids.join(','),
                            "name": content.linkTitle,
                            "data": content.status
                        }
                    } else{
                        shareItem.userData = {
                            "recipients": chat_ids.join(','),
                            "name": content.name,
                            "data": content.data
                        }
                    }
                } else {
                    shareItem.userData = {
                        "recipients": chat_ids.join(',')
                    }
                }
                shareItem.start()
                root.dismiss()
            }
        }
    }

    delegate: ChatItemShare {
        id: chatDelegate
        ListView.onAdd: AddAnimation {
            target: chatDelegate
        }

        ListView.onRemove: RemoveAnimation {
            target: chatDelegate
        }

        onClicked: {
            var contains = false
            for(var i = 0; i < chat_ids.length; i++)
                if ( chat_ids[i] === id)
                    contains = true
            if (!contains) {
                chat_ids.push(id)
                highlighted = true
            } else {
                for(i = 0; i < chat_ids.length; i++){
                    if ( chat_ids[i] === id) {
                        highlighted = false
                        chat_ids.splice(i, 1);
                    }
                }
            }
            chat_ids_length = chat_ids.length
        }
    }
    ViewPlaceholder {
        enabled:listModel.count ===  0
        text: qsTr("Ensure that depecher is running")
        hintText: qsTr("Do not close until media is transfered")
    }

    Component.onCompleted: {
        shareItem.loadConfiguration(shareAction.toConfiguration())
    }

    SailfishTransfer {
        id: shareItem
        metadataStripped: true
        userData: {"description": "Depecher"}
    }
}
