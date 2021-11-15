#include "JoinManager.hpp"
#include "tdlibQt/TdlibJsonWrapper.hpp"
#include "tdlibQt/infoProviders/UsernameResolver.hpp"
#include "tdlibQt/infoProviders/ChannelInfoProvider.hpp"
#include "tdlibQt/ParseObject.hpp"
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
        m_url = link;
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
    connect(usernameResolver, &UsernameResolver::chatTypeEnumChanged,
            usernameResolver, [this, usernameResolver]()
    {
        tryToJoin(usernameResolver->resolvedChatId(), usernameResolver->chatTypeEnum(),
                  usernameResolver->resolvedTitle(), usernameResolver->resolvedId());

        usernameResolver->deleteLater();
    });
    connect(usernameResolver, &UsernameResolver::errorChanged,
            usernameResolver, [this, usernameResolver]() {
        usernameResolver->deleteLater();
        emit errorMessage(usernameResolver->error());
    });
}

void JoinManager::tryToJoin(const qint64 chatId, QSharedPointer<ChatType> chatType, const QString &title)
{
    Enums::ChatType chatTypeEnum = ParseObject::chatTypeToChatTypeEnum(chatType);
    int supergroupId = -1;
    if (chatType->get_id() == chatTypeSupergroup::ID)
        supergroupId = static_cast<chatTypeSupergroup *>(chatType.data())->supergroup_id_;

    tryToJoin(chatId, chatTypeEnum, title, supergroupId);
}

void JoinManager::tryToJoin(const qint64 chatId, Enums::ChatType chatTypeEnum, const QString title, int supergroupId)
{
    if (chatTypeEnum == Enums::ChatType::Supergroup || chatTypeEnum == Enums::ChatType::Channel) {
        ChannelInfoProvider *channelInfoProvider = new ChannelInfoProvider(this);
        channelInfoProvider->setSupergroupId(supergroupId);
        connect(channelInfoProvider, &ChannelInfoProvider::infoReady,
                channelInfoProvider, [this, channelInfoProvider, title, chatId] ()
        {
            QString restrictionReason = channelInfoProvider->restrictionReason();
            if (restrictionReason.isEmpty())
                emit inviteIdReady(title, chatId);
            else
                emit errorMessage(restrictionReason);
            channelInfoProvider->deleteLater();
        });
        connect(channelInfoProvider, &ChannelInfoProvider::errorChanged,
                channelInfoProvider, &ChannelInfoProvider::deleteLater);

    } else if (chatTypeEnum != Enums::ChatType::Private) {
        emit inviteIdReady(title, chatId);
    }
}

void JoinManager::chatInviteLinkInfoRecieved(const QJsonObject &chatInfo)
{
    if (chatInfo["@extra"].toString() != c_extra)
        return;

    qint64 chatId = ParseObject::getInt64(chatInfo["chat_id"]);
    QString title = chatInfo["title"].toString();
    if (chatId != 0) {
        auto chatType = ParseObject::parseType(chatInfo["type"].toObject());
        tryToJoin(chatId, chatType, title);
    } else { // no access before joining
        emit inviteLinkReady(title, m_url);
    }
}

} //namespace tdlibQt
