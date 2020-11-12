#include "tdlibQt/include/TdlibNamespace.hpp"
#include "ShareChatPlugin.hpp"
#include "ChatShareModel.hpp"
#include <qqml.h>

void ShareChatPlugin::initializeEngine(QQmlEngine *, const char *)
{
    // Does it need to be removed?
    QTranslator *translator = new QTranslator(qApp);
    translator->load(QLocale::system(), "depecher", "-", "/usr/share/depecher/translations");
    if (!qApp->installTranslator(translator)) {
        qDebug() << "Depecher: Can not install translator";
        translator->deleteLater();
    }
}

void ShareChatPlugin::registerTypes(const char *uri)
{
    // @uri org.blacksailer.depecher.sharechat
    qmlRegisterUncreatableType<tdlibQt::Enums>(uri, 1, 0, "TdlibState",
            "Error class uncreatable");
    qmlRegisterType<ChatShareModel>(uri, 1, 0, "ShareChatModel");
}
