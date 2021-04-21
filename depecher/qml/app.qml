import QtQuick 2.0
import Sailfish.Silica 1.0
import tdlibQtEnums 1.0
import TelegramModels 1.0
import QtMultimedia 5.6
import Nemo.Configuration 1.0

ApplicationWindow
{
    id:rootWindow
    property alias __depecher_audio: playMusic
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: allowedOrientations
    initialPage: Qt.resolvedUrl("pages/DialogsPage.qml")
    // TODO: do not hardcode #99000000 Theme.rgba("black", 0.6)
    background.color: settingsNightMode.enabled ? "#101011" : "#99000000"

    Audio {
        id: playMusic
        audioRole: Audio.MusicRole
        onError: console.log(error,errorString)
    }

    onApplicationActiveChanged: {
        if (Qt.application.active) {
            var pages =[];
            var listPages = c_PageStarter.getPages();
            var page_dialog=Qt.resolvedUrl("pages/MessagingPage.qml")
            if(listPages.length>0)
            {
                var page = pageStack.find(function (page) {
                    return page.__chat_page !== undefined;
                });
                if(pageStack.depth > 1)
                    pageStack.popAttached(page,PageStackAction.Immediate)
                page._opened_chat_id = listPages[0].pageParam
                pageStack.pushAttached(page_dialog,{chatId:listPages[0].pageParam})
                pageStack.navigateForward()
            }
        }
    }

    ConfigurationGroup {
        id: settingsNightMode
        path: "/apps/depecher/ui"
        property bool enabled: false
        property bool scheduleMode: false
        property string from: "1900-01-01T22:00:00"
        property string till: "1900-01-01T08:00:00"
    }

    Timer {
        id: nightModeScheduleTimer
        interval: 1000 * 30
        repeat: true
        running: settingsNightMode.scheduleMode
        triggeredOnStart: true
        onTriggered: {
            var currDate = new Date()
            var fromDate = new Date(settingsNightMode.from)
            var tillDate = new Date(settingsNightMode.till)
            // in minutes
            var curr = currDate.getHours() * 60 + currDate.getMinutes()
            var from = fromDate.getHours() * 60 + fromDate.getMinutes()
            var till = tillDate.getHours() * 60 + tillDate.getMinutes()
            if (from <= till)
                settingsNightMode.enabled = (curr >= from && curr <= till)
            else if (from > till)
                settingsNightMode.enabled = (curr <= till || curr >= from)
        }
    }
}

