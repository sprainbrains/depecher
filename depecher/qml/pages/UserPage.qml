import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramDAO 1.0
import tdlibQtEnums 1.0
import TelegramModels 1.0
import Nemo.Notifications 1.0
import "items"
import "items/delegates"
import "items/filter_delegates"
Page {
    id: page
    property int user_id: -1
    property int supergroup_id: -1
    property double chat_id: -1
    property alias username: resolver.username
    property bool hideOpenMenu: false
    readonly property string httpTgPrefix: "https://t.me/"
    property string tgDN: ""
    signal filterChatMembersModelChanged(var membersModel)

    Component.onCompleted: {
        if(user_id > -1 && username == "")
        {
            loader.sourceComponent  = userInfoComponent
            loader.item.chatId=user_id
            loader.item.userId=user_id
        }
        if  (chat_id !== -1)      {
            loader.sourceComponent  = channelInfoComponent
            loader.item.chatId=chat_id
            loader.item.hideOpenMenu=hideOpenMenu
        }
    }
    Notification {
        id: notificationError
        appName: "Depecher"
        expireTimeout: 1
    }

    UsernameResolver {
        id:resolver
        onChatTypeEnumChanged: {
            if(resolver.chatTypeEnum === TdlibState.Private) {
                loader.sourceComponent  = userInfoComponent
                loader.item.chatId=resolver.resolvedChatId
                loader.item.userId=resolver.resolvedId
            } else {
                loader.sourceComponent  = channelInfoComponent
                loader.item.chatId=resolver.resolvedChatId
                loader.item.supergroupId=resolver.resolvedId
            }
        }
    }

    Loader {
        id:loader
        anchors.fill: parent
    }
    ContextMenu {
        id: tgDNCtxMenu
        MenuItem {
            text: qsTr("Copy")
            onClicked: Clipboard.text = "@" + tgDN
        }
        MenuItem {
            text: qsTr("Copy link")
            onClicked: Clipboard.text = httpTgPrefix + tgDN
        }
    }
    Component {
        id:userInfoComponent
        SilicaFlickable {
            id: userInfoFlickable
            anchors.fill: parent
            visible: !errorPlaceholder.enabled
            contentHeight: content.height + header.height

            property alias chatId: userInfo.chatId
            property alias userId: userInfo.userId

            UserInfo {
                id:userInfo
            }

            function pushMessagingPage(cid) {
                var chatsPage = app.chatsPage
                pageStack.pop(chatsPage, PageStackAction.Immediate)
                chatsPage._opened_chat_id = cid
                pageStack.pushAttached("MessagingPage.qml",{"chatId": cid})
                pageStack.navigateForward()
            }

            Connections {
                target: userInfo
                onChatIdReceived: { // private chat
                    userInfoFlickable.pushMessagingPage(chatId)
                }
            }

            ViewPlaceholder {
                id:errorPlaceholder
                enabled:resolver.error != ""
                text: resolver.error
            }

            PageHeader {
                id:header
                title:qsTr("User info")
            }
            PullDownMenu {
                MenuItem {
                    text: qsTr("Send message")
                    onClicked: {
                        var cid = userInfo.getChatId() // -1 creates private chat
                        if (cid !== "-1")
                            userInfoFlickable.pushMessagingPage(cid)
                    }
                }
            }
            Column {
                id:content
                width: parent.width
                anchors.top: header.bottom
                Row {
                    width: parent.width - 2 * x
                    x:Theme.horizontalPageMargin
                    CircleImage {
                        id: avatar
                        width: Theme.itemSizeLarge
                        height: width
                        source: userInfo.avatar
                        fallbackText: userInfo.firstName != "" ? userInfo.firstName.charAt(0) :userInfo.lastName.charAt(0)
                        fallbackItemVisible: userInfo.avatar == ""

                    }
                    Item {
                        width: Theme.paddingLarge
                        height:Theme.paddingLarge
                    }

                    Column {
                        width: parent.width - avatar.width - Theme.paddingLarge
                        anchors.verticalCenter:   parent.verticalCenter
                        Label {
                            text: userInfo.firstName + " " + userInfo.lastName
                            font.pixelSize: Theme.fontSizeMedium
                            width:parent.width
                        }
                        Label {
                            font.pixelSize: Theme.fontSizeTiny
                            text: userInfo.status
                            color:Theme.secondaryColor

                            width:parent.width
                        }
                    }
                }
                Item {
                    width: 1
                    height:Theme.paddingLarge
                }
                Column {
                    width: parent.width
                    BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeSmall
                        visible: userInfo.phoneNumber != ""
                        Row {
                            width: parent.width - 2 * x
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            Icon {
                                id:iconPhone
                                source: "image://theme/icon-m-device"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item {
                                width: Theme.paddingLarge
                                height: Theme.paddingLarge
                            }
                            Column {
                                width: parent.width - iconPhone.width - Theme.paddingLarge
                                anchors.verticalCenter: parent.verticalCenter

                                Label {
                                    text: userInfo.phoneNumber
                                }
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    color:Theme.secondaryColor
                                    text: qsTr("Phone number")
                                    width: parent.width
                                }
                            }
                        }
                        onClicked: Qt.openUrlExternally("tel:" + userInfo.phoneNumber)
                    }
                    BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeSmall
                        visible: userInfo.username != ""

                        Row {
                            width: parent.width - 2 * x
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            Item {
                                width:Theme.paddingLarge + Theme.iconSizeMedium
                                height: Theme.paddingLarge
                            }
                            Column {
                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                                anchors.verticalCenter:   parent.verticalCenter
                                Label {
                                    text:"@"+userInfo.username
                                    width:parent.width
                                }
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    color:Theme.secondaryColor
                                    text: qsTr("Username")
                                    width:parent.width
                                }
                            }

                        }
                        onPressAndHold: {
                            tgDN = userInfo.username
                            tgDNCtxMenu.open(hiddenUserInfoUsername)
                        }
                    }
                    Item {
                        id: hiddenUserInfoUsername
                        height: tgDNCtxMenu.visible ? tgDNCtxMenu.height : 0
                        width: parent.width
                    }
                    BackgroundItem {
                        width: parent.width
                        height: bioWrapper.height
                        visible: userInfo.bio != ""

                        Row {
                            width: parent.width - 2 * x
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            Item {
                                width: Theme.paddingLarge + Theme.iconSizeMedium
                                height: Theme.paddingLarge
                            }
                            Column {
                                id: bioWrapper
                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                                anchors.verticalCenter: parent.verticalCenter
                                RichTextItem {
                                    text: userInfo.bio
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    color: Theme.secondaryColor
                                    text: qsTr("Bio")
                                    width:parent.width
                                }
                            }
                        }
                    }
                    IconTextSwitch {
                        text: qsTr("Notifications")
                        description: checked ? qsTr("Click to disable notifications") :  qsTr("Click to enable notifications")
                        icon.source: checked ? "image://theme/icon-m-speaker-on" :  "image://theme/icon-m-speaker-mute"
                        automaticCheck: false
                        checked: userInfo.muteFor == 0
                        onClicked: userInfo.changeNotifications(checked)
                    }
                }
                Item {
                    width: 1
                    height:Theme.paddingLarge
                }

                SharedContent {
                    chatId: userInfo.chatId

                    photoCount: userInfo.photoCount
                    videoCount: userInfo.videoCount
                    fileCount: userInfo.fileCount
                    audioCount: userInfo.audioCount
                    linkCount: userInfo.linkCount
                    voiceCount: userInfo.voiceCount
                    animationCount: userInfo.animationCount
                }
                BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeSmall
                    visible: userInfo.groupCount
                    Row {
                        width: parent.width - 2 * x
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.horizontalPageMargin
                        Icon {
                            id:iconVoices
                            source: "image://theme/icon-m-people"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Item {
                            width: Theme.paddingLarge
                            height: Theme.paddingLarge
                        }
                        Label {
                            width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                            text:qsTr("%1 groups in common").arg(userInfo.groupCount)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }

                Item {
                    width: 1
                    height:Theme.paddingLarge
                }

                //                Column {
                //                    width: parent.width
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Share contact"
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Edit contact"
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Delete contact"
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Clear history"
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Delete conversation"
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }
                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:"Block user"
                //                                color:Theme.errorColor
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }

                //                }

            }
        }

    }

    // Supergroup
    Component {
        id:channelInfoComponent
        SilicaFlickable {
            id:flickable
            property alias chatId: channelInfo.chatId
            property alias supergroupId: channelInfo.supergroupId
            property bool hideOpenMenu: false
            property int sourceModelCount: filterMembersModel.sourceModel ? filterMembersModel.sourceModel.count : 0

            ChannelInfo {
                id:channelInfo
                onMembersModelChanged: {
                    filterMembersModel.sourceModel = channelInfo.membersModel
                    page.filterChatMembersModelChanged(filterMembersModel)
                }
            }

            Connections {
                target: page
                onStatusChanged: {
                    if (page.status == PageStatus.Inactive) {
                        searchField.text = ""
                        searchField.focus = false
                    }
                }
            }

            Connections {
                target: channelInfo
                onErrorChanged: {
                    notificationError.summary = errorPlaceholder
                    notificationError.publish()
                }
            }
            anchors.fill: parent
            visible: !errorPlaceholder.enabled
            contentHeight: content.height + header.height

            ViewPlaceholder {
                id:errorPlaceholder
                enabled:resolver.error != ""
                text: resolver.error
            }

            PageHeader {
                id:header
                title:qsTr("Channel info")
            }
            PullDownMenu {
                MenuItem {
                    text: channelInfo.isMember ?  qsTr("Leave channel") : qsTr("Join channel")
                    onClicked: {
                        if(channelInfo.isMember)
                            leaveRemorse.execute(qsTr("Leaving"), function() {
                                channelInfo.leaveChat()
                            })
                        else
                            channelInfo.joinChat()
                    }
                }
                MenuItem {
                    text: qsTr("Open channel")
                    visible: !flickable.hideOpenMenu
                    onClicked:{
                        var chatsPage = app.chatsPage
                        pageStack.replaceAbove(chatsPage,"MessagingPage.qml",{chatId:channelInfo.chatId})

                    }
                }
                RemorsePopup {
                    id:leaveRemorse
                }
            }

            Column {
                id:content
                width: parent.width
                anchors.top: header.bottom
                Row {
                    width: parent.width - 2 * x
                    x:Theme.horizontalPageMargin
                    CircleImage {
                        id: avatar
                        width: Theme.itemSizeLarge
                        height: width
                        source: channelInfo.avatar
                        fallbackText: channelInfo.name.charAt(0)
                        fallbackItemVisible: channelInfo.avatar == ""

                    }
                    Item {
                        width: Theme.paddingLarge
                        height:Theme.paddingLarge
                    }

                    Column {
                        width: parent.width - avatar.width - Theme.paddingLarge
                        anchors.verticalCenter:   parent.verticalCenter
                        Label {
                            text: channelInfo.name
                            font.pixelSize: Theme.fontSizeMedium
                            width:parent.width
                        }
                        Label {
                            font.pixelSize: Theme.fontSizeTiny
                            text: qsTr('%1 members').arg(channelInfo.members)
                            color:Theme.secondaryColor

                            width:parent.width
                        }
                    }
                }
                Item {
                    width: 1
                    height:Theme.paddingLarge
                }
                Column {
                    width: parent.width
                    BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeSmall
                        visible: channelInfo.link != ""
                        Row {
                            width: parent.width - 2 * x
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            Icon {
                                id:iconPhone
                                source: "image://theme/icon-m-device"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item {
                                width: Theme.paddingLarge
                                height: Theme.paddingLarge
                            }
                            Label {
                                width: parent.width - iconPhone.width - Theme.paddingLarge
                                text:channelInfo.link
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onPressAndHold: {
                            tgDN = channelInfo.link
                            tgDNCtxMenu.open(hiddenChannelInfoLink)
                        }
                    }
                    Item {
                        id: hiddenChannelInfoLink
                        height: tgDNCtxMenu.visible ? tgDNCtxMenu.height : 0
                        width: parent.width
                    }
                    BackgroundItem {
                        width: parent.width
                        height: descriptionWrapper.height
                        visible:channelInfo.description != ""

                        Row {
                            width: parent.width - 2 * x
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            Item {
                                width:Theme.paddingLarge + Theme.iconSizeMedium
                                height: Theme.paddingLarge
                            }
                            Column {
                                id:descriptionWrapper
                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                                anchors.verticalCenter:   parent.verticalCenter
                                RichTextItem {
                                    text:channelInfo.description
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                    width:parent.width
                                }
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    color:Theme.secondaryColor
                                    text: qsTr("Description")
                                    width:parent.width
                                }
                            }

                        }
                    }
                    IconTextSwitch {
                        text: qsTr("Notifications")
                        description: checked ? qsTr("Click to disable notifications") :  qsTr("Click to enable notifications")
                        icon.source: checked ? "image://theme/icon-m-speaker-on" :  "image://theme/icon-m-speaker-mute"
                        automaticCheck: false
                        checked: channelInfo.muteFor == 0
                        onClicked: {
                            channelInfo.changeNotifications(checked)
                        }
                    }
                }
                Item {
                    width: 1
                    height:Theme.paddingLarge
                }


                SharedContent {
                    chatId:channelInfo.chatId

                    photoCount:channelInfo.photoCount
                    videoCount:channelInfo.videoCount
                    fileCount:channelInfo.fileCount
                    audioCount:channelInfo.audioCount
                    linkCount:channelInfo.linkCount
                    voiceCount:channelInfo.voiceCount
                    animationCount:channelInfo.animationCount
                }

                //                Column {
                //                    width: parent.width

                //                    BackgroundItem {
                //                        width: parent.width
                //                        height: Theme.itemSizeSmall
                //                        Row {
                //                            width: parent.width - 2 * x
                //                            anchors.verticalCenter: parent.verticalCenter
                //                            x: Theme.horizontalPageMargin
                //                            Item {
                //                                width: Theme.paddingLarge + Theme.iconSizeMedium
                //                                height: Theme.paddingLarge
                //                            }
                //                            Label {
                //                                width: parent.width - Theme.iconSizeMedium - Theme.paddingLarge
                //                                text:qsTr('Report')
                //                                color:Theme.errorColor
                //                                anchors.verticalCenter: parent.verticalCenter
                //                            }
                //                        }
                //                    }

                //                }

                SearchField {
                    id: searchField
                    width: membersList.width
                    placeholderText: qsTr("Search")
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    focusOutBehavior: FocusBehavior.ClearItemFocus
                    autoScrollEnabled: false
                    visible: flickable.sourceModelCount

                    Component.onCompleted: membersList.searchField = searchField

                    onFocusChanged: {
                        flickable.scrollToBottom()
                    }

                    onTextChanged: {
                        filterMembersModel.search = text
                        flickable.scrollToBottom()
                    }
                }

                SilicaListView {
                    id:membersList
                    width: parent.width
                    height: flickable.sourceModelCount ? (page.height - searchField.height) : 0
                    clip:true
                    interactive: flickable.atYEnd || !membersList.atYBeginning
                    property SearchField searchField

                    model: FilterChatMembersModel {
                        id: filterMembersModel
                        showDeleted: page.visible
                    }
                    delegate: BackgroundItem {
                        width: membersList.width
                        height: Theme.itemSizeSmall
                        Row {
                            width: parent.width - 2 * x
                            height: parent.height
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            CircleImage {
                                id:userPhoto
                                source: avatar ? avatar : ""
                                fallbackItemVisible: avatar == undefined
                                fallbackText:name.charAt(0)
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.height - 3*Theme.paddingSmall
                            }
                            Item {
                                width: Theme.paddingLarge
                                height: Theme.paddingLarge
                            }
                            Column {
                                width: parent.width - userPhoto.width
                                anchors.verticalCenter:   parent.verticalCenter

                                Label {
                                    property string mText: model.deleted ? "Deleted account" : (name + (username ? " @" + username : ""))
                                    text: membersList.searchField.text.length ?
                                              Theme.highlightText(mText, filterMembersModel.search, Theme.highlightColor) : mText
                                    font.pixelSize: Theme.fontSizeMedium
                                    width: parent.width
                                }
                                Label {
                                    font.pixelSize: Theme.fontSizeTiny
                                    color:Theme.secondaryColor
                                    text: online_status
                                    width:parent.width
                                    visible: text.length
                                    height: !visible ? 0 : contentHeight
                                }
                            }
                        }
                        onClicked: {
                            var userId = parseInt(model.user_id)
                            if (userId !== -1)
                                pageStack.push(Qt.resolvedUrl("UserPage.qml"),{"user_id": userId})
                        }
                    }

                    VerticalScrollDecorator {
                        flickable: membersList
                    }
                }
            }
        }

    }
}
