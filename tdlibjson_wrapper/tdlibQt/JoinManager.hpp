#ifndef JOINMANAGER_H
#define JOINMANAGER_H

#include <QObject>
#include "tdlibQt/include/TdlibNamespace.hpp"

namespace tdlibQt {
class TdlibJsonWrapper;
class ChatType;
class JoinManager : public QObject
{
    Q_OBJECT
public:
    explicit JoinManager(QObject *parent = nullptr);

private:
    TdlibJsonWrapper *m_tdlibJson;
    QString m_url;

private:
    void parseUrl(const QString &url);
    void onAuthorizationStateChanged(const Enums::AuthorizationState state);
    void chatInviteLinkInfoRecieved(const QJsonObject &chatInfo);
    void processFile(const QJsonObject &fileObject);
    void resolveName(const QString &name);
    void tryToJoin(const qint64 chatId, QSharedPointer<ChatType> chatType, const QString &title);
    void tryToJoin(const qint64 chatId, Enums::ChatType chatTypeEnum, const QString title, int supergroupId);

public slots:
    void openUrl(const QString &url);

signals:
    void inviteLinkReady(const QString &title, const QString &link);
    void inviteIdReady(const QString &title, qint64 chatId);
    void errorMessage(const QString &errorMessage);
};

} //namespace tdlibQt
#endif // JOINMANAGER_H
