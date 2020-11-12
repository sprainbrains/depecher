#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QGuiApplication>
#include <MGConfItem>

#include "tdlibQt/TdlibJsonWrapper.hpp"
#include "tdlibQt/NotificationManager.hpp"
#include "tdlibQt/models/singletons/UsersModel.hpp"
#include "DBusAdaptor.hpp"
#include "dbus/DBusShareAdaptor.hpp"
#include "dbus/ChatShareAdaptor.hpp"
#include "src/fileGeneratedHandlers/FileGeneratedHandler.hpp"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    if (DBusAdaptor::isRegistered()) {
        if (DBusAdaptor::raiseApp()) {
            return 0;
        } else {
            return 1;
        }
    }

    QScopedPointer<DBusAdaptor> dbusWatcher(new DBusAdaptor(app.data()));
    QScopedPointer<DBusShareAdaptor> dbusShareWatcher(new DBusShareAdaptor(app.data()));
    QScopedPointer<ChatShareAdaptor> dbusChatShareWatcher(new ChatShareAdaptor(app.data()));
    app->addLibraryPath(QString("%1/../share/%2/lib").arg(qApp->applicationDirPath(),
                        qApp->applicationName()));
    app->setApplicationVersion(APP_VERSION);


    QTranslator translator;

    QString locale = QLocale::system().name();
    //locale="de"; // for testing purposes only
    if (!translator.load("depecher-" + locale, SailfishApp::pathTo("translations").toLocalFile())) {
        qDebug() << "Couldn't load translation for locale " + locale + " from " +
                 SailfishApp::pathTo("translations").toLocalFile();
    }
    app->installTranslator(&translator);


    //Need to create at first launch. Bad design maybe, should change
    auto tdlib = tdlibQt::TdlibJsonWrapper::instance();
    auto NotificationManager = tdlibQt::NotificationManager::instance();
    auto usersmodel = tdlibQt::UsersModel::instance();
    Q_UNUSED(usersmodel)
    tdlib->startListen();
    //used in authenticationhandler too.
//    tdlib->setEncryptionKey();
    FileGeneratedHandler generationHandler(app.data());
    Q_UNUSED(generationHandler)

    app->setQuitOnLastWindowClosed(false);
    MGConfItem quitOnCloseUi("/apps/depecher/tdlib/quit_on_close_ui");
    if (quitOnCloseUi.value(false).toBool()) {
        QObject::connect(dbusWatcher.data(), &DBusAdaptor::viewDestroyed,
                         tdlib, [&app, &tdlib] () {
            tdlib->close();
            // In case tdlib close fail
            QTimer *closeTimer = new QTimer(tdlib);
            closeTimer->start(5000);
            QObject::connect(closeTimer, &QTimer::timeout,
                             app.data() , &QGuiApplication::quit);
        });

        DBusAdaptor::raiseApp();
    } else {
        QObject::connect(app.data(), &QGuiApplication::aboutToQuit,
                         NotificationManager, &tdlibQt::NotificationManager::removeAll);
    }

    return app->exec();
}
