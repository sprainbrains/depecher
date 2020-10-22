#include "JoinManager.hpp"
#include "tdlibQt/TdlibJsonWrapper.hpp"
#include "tdlibQt/infoProviders/UsernameResolver.hpp"
#include <QRegularExpression>

namespace tdlibQt {

static const QString c_extra = QLatin1String("JoinManager");

JoinManager::JoinManager(QObject *parent) :
    QObject(parent),
    m_tdlibJson(TdlibJsonWrapper::instance())
{
    connect(m_tdlibJson, &TdlibJsonWrapper::chatInviteLinkInfoReceived,
            this, &JoinManager::chatInviteLinkInfoRecieved);
}

void JoinManager::onAuthorizationStateChanged(const Enums::AuthorizationState state)
{
    if (!m_url.isEmpty() &&
        state == Enums::AuthorizationState::AuthorizationStateReady) {
        parseUrl(m_url);
        disconnect(m_tdlibJson, &TdlibJsonWrapper::authorizationStateChanged,
                   this, &JoinManager::onAuthorizationStateChanged);
    }
}

void JoinManager::openUrl(const QString &url)
{
    qDebug() << "openUrl: " << url;
    m_url = url;
    if (m_tdlibJson->authorizationState() == Enums::AuthorizationState::AuthorizationStateReady)
        parseUrl(url);
    else
        connect(m_tdlibJson, &TdlibJsonWrapper::authorizationStateChanged,
                this, &JoinManager::onAuthorizationStateChanged);
}

void JoinManager::parseUrl(const QString &url)
{
    if (url.startsWith("tg://join?invite=")) {
        QString link = "https://t.me/joinchat/" + url.split("=").last();
        m_tdlibJson->checkChatInviteLink(link, c_extra);
    } else if (url.startsWith("tg://resolve?domain=")) {
        QString name = url.split("=").last();
        resolveName(name);
    } else {
        QRegularExpression re("https://(t\\.me|telegram\\.me|telegram\\.dog)/joinchat/.+");
        if (re.match(url).hasMatch()) {
            m_tdlibJson->checkChatInviteLink(url, c_extra);
        } else {
            re.setPattern("https://t\\.me/([\\w-]+)");
            auto match = re.match(url);
            if (match.hasMatch()) {
                QString name = match.captured(1);
                resolveName(name);
            }
        }
    }
}

void JoinManager::resolveName(const QString &name)
{
    UsernameResolver *usernameResolver = new UsernameResolver(this);
    usernameResolver->setUsername(name);
    connect(usernameResolver, &UsernameResolver::chatTypeChanged,
            usernameResolver, [this, usernameResolver](){
        Enums::ChatType chatType = usernameResolver->chatType();
        if (chatType != Enums::ChatType::Private)
            emit inviteIdReady(usernameResolver->resolvedTitle(), usernameResolver->resolvedChatId());
        usernameResolver->deleteLater();
    });
    connect(usernameResolver, &UsernameResolver::errorChanged,
            usernameResolver, [this, usernameResolver](){
        qDebug() << "error: " << usernameResolver->error();
        usernameResolver->deleteLater();
    });
}

void JoinManager::chatInviteLinkInfoRecieved(const QJsonObject &chatInfo)
{
    if (chatInfo["@extra"].toString() != c_extra)
        return;

    QString title = chatInfo["title"].toString();
    emit inviteLinkReady(title, m_url);
}

} //namespace tdlibQt
