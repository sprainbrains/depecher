import QtQuick 2.6
import Sailfish.Silica 1.0
import TelegramAuthentication 1.0
import tdlibQtEnums 1.0
import ".."
import "../../../js/utils.js" as Utils

Dialog {
    id:signInDialog
    property string fullPhoneNumber: ""
    property bool canLogin: false
    canAccept: canLogin

    NotificationPanel{ // TODO replace with new in-app notifications
        id: notificationPanel
        page: signInDialog
    }

    SilicaFlickable{
        anchors.fill: parent
        contentHeight: flickableColumn.height

        TelegramAuthenticationHandler {
            id:telegramAuthenticationHandler
            property bool forgotPassword: false

            onAuthorizationStateChanged: {
                switch (currentAuthorizationState) {
                case TdlibState.AuthorizationStateWaitPassword:
                    signInDialog.state = "password"
                    break
                case TdlibState.AuthorizationStateWaitCode:
                    signInDialog.state = "code"
                    break
                case TdlibState.AuthorizationStateWaitRegistration:
                    signInDialog.state = "register"
                    break;
                case TdlibState.AuthorizationStateReady:
                    canLogin=true
                    pageStack.replaceAbove(null,Qt.resolvedUrl("../../DialogsPage.qml"))
                    break
                }
            }

            onErrorChanged: {
                notificationPanel.showTextWithTimer(qsTr("Error"),"code:" + error["code"] +"\n" + error["message"])
            }

        }

        PullDownMenu {
            id:pulleyMenuRecovery
            visible: false

            MenuItem{
                text:qsTr("Recover password")
                enabled: telegramAuthenticationHandler.hasRecoveryEmail
                onClicked: {
                    hintLabel.visible = false
                    telegramAuthenticationHandler.recoverPassword()
                    telegramAuthenticationHandler.forgotPassword = true
                    notificationPanel.showTextWithTimer(qsTr("Email is sent"),qsTr("recovery code sent to %1").arg(telegramAuthenticationHandler.emailPattern))

                }
            }

            MenuItem {
                text:qsTr("Show hint")
                onClicked: hintLabel.visible = true
            }
        }

        states:[
            State {
                name: "password"
                when: telegramAuthenticationHandler.currentAuthorizationState === TdlibState.AuthorizationStateWaitPassword
                PropertyChanges {
                    target: keyColumn
                    visible:true
                }
                PropertyChanges {
                    target: signin
                    visible:false
                }

                PropertyChanges {
                    target: pulleyMenuRecovery
                    visible:true
                }
            },
            State {
                name: "code"
                when: telegramAuthenticationHandler.currentAuthorizationState === TdlibState.AuthorizationStateWaitCode
                PropertyChanges {
                    target: signin
                    visible:true
                }
            },
            State {
                name: "register"
                when: telegramAuthenticationHandler.currentAuthorizationState === TdlibState.AuthorizationStateWaitRegistration
                PropertyChanges {
                    target: signin
                    visible: true
                }
                PropertyChanges {
                    target: tfRowName
                    visible: true
                }
                PropertyChanges {
                    target: btnsignin
                    text: qsTr("Sign up")
                    enabled: tfcode.text.length > 0 && tfName.text.length > 0
                             && tfSurName.text.length > 0
                }
            }

        ]

        Column {
            id: flickableColumn
            width: signInDialog.width

            PageHeader {
                id:header
                title: {
                    switch (state) {
                    case "code": return qsTr("Enter code")
                    case "register": return qsTr("Enter your name")
                    default: return qsTr("Enter password")
                    }
                }
                description: qsTr("Authentication state") +" - "+Utils.setAuthState(telegramAuthenticationHandler.currentAuthorizationState)
            }

            Column {
                id:keyColumn
                spacing: Theme.paddingMedium
                x:Theme.horizontalPageMargin
                topPadding: Theme.paddingLarge
                width: parent.width-2*x
                visible: false
                Image {
                    id: imglock
                    source: "image://theme/icon-m-device-lock"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    id: lblInfoPass
                    text: telegramAuthenticationHandler.forgotPassword ? qsTr("Enter recovery code. \n Remember! After that 2FA authorization will be disabled") : qsTr("Enter your password")
                    font.pixelSize: Theme.fontSizeSmall
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                PasswordField {
                    id: tfPassword
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
                    placeholderText: telegramAuthenticationHandler.forgotPassword ? qsTr("Recovery code") : qsTr("Password")
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                }
                Label {
                    id:hintLabel
                    visible: false
                    text:qsTr("Password hint")+ " - " + telegramAuthenticationHandler.getHint
                    font.pixelSize: Theme.fontSizeSmall
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Button {
                    id: btnpassword
                    anchors { horizontalCenter: parent.horizontalCenter }
                    text: qsTr("Sign In")
                    enabled: tfPassword.text.length > 0
                    onClicked: {
                        if(telegramAuthenticationHandler.forgotPassword)
                            telegramAuthenticationHandler.sendRecoveryCode(tfPassword.text)
                        else
                            telegramAuthenticationHandler.checkPassword(tfPassword.text)
                    }
                }
            }

            Column {
                id: signin
                spacing: Theme.paddingMedium
                x:Theme.horizontalPageMargin
                width: parent.width-2*x
                topPadding: Theme.paddingLarge
                visible: true
                Image {
                    id: imgwaiting
                    source: "image://theme/icon-l-timer"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    id: lblinfo
                    text: qsTr("Wait for the message via %1 containing the activation code and press %2" ).arg(telegramAuthenticationHandler.getType).arg(telegramAuthenticationHandler.isUserRegistered ? qsTr("Sign In") : qsTr("Sign up"))
                    font.pixelSize: Theme.fontSizeSmall
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                TextField  {
                    id: tfcode
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
                    placeholderText: qsTr("Code")
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhDigitsOnly
                }
                Column {
                    id:tfRowName
                    width:parent.width
                    visible: false
                    TextField {
                        id: tfName
                        width:parent.width
                        placeholderText: qsTr("First Name")
                    }
                    TextField {
                        id: tfSurName
                        width:parent.width
                        placeholderText: qsTr("Surname")
                    }
                }

                Button  {
                    id: btnsignin
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Sign In")
                    enabled: tfcode.text.length > 0
                    onClicked: {
                        btnsignin.enabled = false;
                        btnsignin.text = qsTr("Sending request...");

                        if (signInDialog.state == "code")
                            c_telegramWrapper.checkCode(tfcode.text)
                        else if (signInDialog.state == "register")
                            c_telegramWrapper.registerUser(tfSurName.text, tfName.text)
                    }
                }
            }
        }
    }
}
