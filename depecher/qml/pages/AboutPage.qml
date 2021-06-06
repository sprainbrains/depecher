import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import depecherUtils 1.0
import "components"

Page {

    Component.onCompleted:  {
        DNSLookup.lookupServer()
    }

    SilicaFlickable{
        anchors.fill: parent
        contentHeight: column.height
        Connections {
            target: c_telegramWrapper
            onGetChatByLink: {
                var page = pageStack.find(function (page) {
                    return page.__chat_page !== undefined;
                });
                pageStack.replaceAbove(page,"MessagingPage.qml",{chatId:chat_id})
            }
            onErrorReceivedMap: {
                notificationProxy.previewBody = qsTr("Error %1").arg(errorObject["code"] ) +" "+ errorObject["message"]
                notificationProxy.publish()
            }
        }
        Notification {
            id:notificationProxy
            appName: "Depecher"
            icon:"image://theme/icon-lock-warning"
        }

        Column {
            id:column
            width:parent.width
            PageHeader{
                title: qsTr("About")
            }
            Label {
                width: parent.width - 2 * x
                x : Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Depecher - Another Telegram client for Sailfish OS based on tdlib.") + "<br><br>" +
                      qsTr("Features:") + "<br>" +
                      qsTr("- Send/View/Delete messages") + "<br>" +
                      qsTr("- Mute/unmute chats") + "<br>" +
                      qsTr("- View photos") + "<br>" +
                      qsTr("- View animations (gifs)") + "<br>" +
                      qsTr("- View/Send stickers") + "<br>" +
                      qsTr("- Manage stickers from chat") + "<br>" +
                      qsTr("- Uploading/Downloading photos/docs") + "<br>" +
                      qsTr("- Receive notifications") + "<br>" +
                      qsTr("- 2FA authorization enabled") + "<br><br>" +
                      qsTr("Incompatible with any sneaky app which creates MIME handler overrides at runtime in ~/.local/share/applications/") + "<br><br>" +
                      qsTr("Thanks to:") + "<br>" +
                      "- @kaffeine" + "<br>" +
                      "- @chuvilin" + "<br>" +
                      "- @icoderus" + "<br>" +
                      "- @aa13q"
            }
            Label {
                width: parent.width - 2 * x
                x : Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Version") + " - " + Qt.application.version
            }
            SectionHeader{
                text: qsTr("Sources")
            }
            BackgroundItem{
                width: parent.width
                height: Theme.itemSizeMedium
                Row{
                    width:parent.width - 2 * x
                    height: parent.height
                    x:Theme.horizontalPageMargin
                    spacing:Theme.paddingMedium
                    Image {
                        width: parent.height
                        height: width
                        source: "qrc:/qml/assets/icons/git.svg"
                    }

                    Label{
                        width: parent.width - parent.height - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: Theme.fontSizeSmall

                        text: "https://github.com/blacksailer/depecher"
                        color: parent.parent.pressed ? Theme.highlightColor : Theme.primaryColor

                    }
                }
                onClicked: Qt.openUrlExternally("https://github.com/blacksailer/depecher")
            }
            SectionHeader{
                text: qsTr("Groups")
            }

            Label {
                width: parent.width - 2 * x

                x: Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Here is enumerated the groups in Telegram where you can ask any questions (general,dev etc.) related to Sailfish OS.") + "<br>" +
                      qsTr("These groups live only for the community and for the community around Sailfish OS.") +"</p>"
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium
                Row{
                    width:parent.width - 2 * x
                    height: parent.height
                    x:Theme.horizontalPageMargin
                    spacing:Theme.paddingMedium
                    Image {
                        width: parent.height
                        height: width
                        source: "qrc:/qml/assets/icons/en_sailfish.jpg"
                    }
                    Column {
                        width: parent.width - parent.height - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        Label{
                            width: parent.width
                            text:qsTr("SailfishOS community of FanClub")
                            truncationMode: TruncationMode.Fade
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label{
                            width: parent.width
                            text:qsTr("English speaking group")
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }

                onClicked: {
                    var url = DNSLookup.inviteLink
                    if (url.indexOf("t.me/joinchat") !== -1) {
                        c_joinManager.openUrl(url)
                    } else {
                        notificationProxy.previewBody = qsTr("Error to get invite link")
                        notificationProxy.publish()
                    }
                }
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium
                Row{
                    width:parent.width - 2 * x
                    height: parent.height
                    x:Theme.horizontalPageMargin
                    spacing:Theme.paddingMedium
                    Image {
                        width: parent.height
                        height: width
                        source: "qrc:/qml/assets/icons/sailfis_es.jpg"
                    }
                    Column {
                        width: parent.width - parent.height - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        Label{
                            width: parent.width
                            text:qsTr("SailfishOS community of Spain")
                            truncationMode: TruncationMode.Fade
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label{
                            width: parent.width
                            text:qsTr("Spanish speaking group")
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
                onClicked: c_joinManager.openUrl("https://t.me/sailfish_es")
            }

            SectionHeader{
                text: qsTr("Donations")
            }
            BackgroundItem{
                width: parent.width
                height: Theme.itemSizeMedium
                Row{
                    width:parent.width - 2 * x
                    height: parent.height
                    x:Theme.horizontalPageMargin
                    spacing:Theme.paddingMedium
                    Image {
                        width: parent.height
                        height: width
                        source: "qrc:/qml/assets/icons/paypal.svg"
                    }
                    Label{
                        width: parent.width - parent.height - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: Theme.fontSizeSmall
                        color: parent.parent.pressed ? Theme.highlightColor : Theme.primaryColor
                        text: "https://paypal.me/blacksailer"
                    }
                }
                onClicked: Qt.openUrlExternally("https://www.paypal.me/blacksailer")
            }
            BackgroundItem{
                width: parent.width
                height: Theme.itemSizeMedium
                Row{
                    width:parent.width - 2 * x
                    height: parent.height
                    x:Theme.horizontalPageMargin
                    spacing:Theme.paddingMedium
                    Image {
                        width: parent.height
                        height: width
                        source: "qrc:/qml/assets/icons/rocket.svg"
                    }
                    Label{
                        width: parent.width - parent.height - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: Theme.fontSizeSmall
                        color: parent.parent.pressed ? Theme.highlightColor : Theme.primaryColor
                        text: "https://rocketbank.ru/ivan.chernenky"
                    }
                }
                onClicked: Qt.openUrlExternally("https://rocketbank.ru/ivan.chernenky")
            }
        }
    }
}
