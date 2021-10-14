#include "DepecherPluginInfo.hpp"
#include <QSysInfo>

DepecherPluginInfo::DepecherPluginInfo() : m_ready(false)
{

}

QList<TransferMethodInfo> DepecherPluginInfo::info() const
{
    return m_infoList;
}

void DepecherPluginInfo::query()
{
    TransferMethodInfo info;

    QString libPath = QSysInfo::currentCpuArchitecture() == "arm64" ? "/usr/lib64" : "/usr/lib";
    // pre 4.2.0.x
    bool legacyShare = !QFileInfo::exists(libPath + "/qt5/qml/Sailfish/Share");

    QStringList capabilities;
    capabilities << QLatin1String("application/*")
                 << QLatin1String("image/*")
                 << QLatin1String("audio/*")
                 << QLatin1String("video/*")
                 << QLatin1String("text/plain")
                 << QLatin1String("text/x-url")
                 << QLatin1String("text/vcard");

    info.displayName     = QLatin1String("Depecher");
    info.methodId        = QLatin1String("DepecherSharePlugin");
    info.accountIcon     = QLatin1String("image://theme/icon-m-depecher");
    info.shareUIPath     = legacyShare ? QLatin1String("/usr/share/depecher/qml/ShareUILegacy.qml") :
                                         QLatin1String("/usr/share/depecher/qml/ShareUI.qml");
    info.capabilitities  = capabilities;
    m_infoList.clear();
    m_infoList << info;

    m_ready = true;
    Q_EMIT infoReady();
}

bool DepecherPluginInfo::ready() const
{
    return m_ready;
}
