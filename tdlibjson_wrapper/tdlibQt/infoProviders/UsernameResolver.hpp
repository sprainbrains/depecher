#ifndef USERNAMERESOLVER_HPP
#define USERNAMERESOLVER_HPP

#include <QObject>
#include  <tdlibQt/include/TdlibNamespace.hpp>
#include <QJsonObject>
namespace tdlibQt {
class TdlibJsonWrapper;
class UsernameResolver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString error READ error WRITE setError NOTIFY errorChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(double resolvedId READ resolvedId WRITE setResolvedId NOTIFY resolvedIdChanged)
    Q_PROPERTY(double resolvedChatId READ resolvedChatId WRITE setResolvedChatId NOTIFY resolvedChatIdChanged)
    Q_PROPERTY(tdlibQt::Enums::ChatType chatTypeEnum READ chatTypeEnum WRITE setChatTypeEnum NOTIFY chatTypeEnumChanged)
    tdlibQt::Enums::ChatType m_chatTypeEnum;

    TdlibJsonWrapper *m_tdlibJson;
    QString m_username = "";
    QString m_resolvedTitle;

    double m_resolvedId = 0;

    double m_resolvedChatId = 0;

    QString m_error = "";

public:
    explicit UsernameResolver(QObject *parent = nullptr);

    tdlibQt::Enums::ChatType chatTypeEnum() const
    {
        return m_chatTypeEnum;
    }

    QString username() const
    {
        return m_username;
    }

    double resolvedId() const
    {
        return m_resolvedId;
    }

    double resolvedChatId() const
    {
        return m_resolvedChatId;
    }

    QString error() const
    {
        return m_error;
    }

    QString resolvedTitle() const
    {
        return m_resolvedTitle;
    }

signals:

    void chatTypeEnumChanged(tdlibQt::Enums::ChatType chatTypeEnum);

    void usernameChanged(QString username);

    void resolvedIdChanged(double resolvedId);

    void resolvedChatIdChanged(double resolvedChatId);
    void errorChanged(QString error);

private slots:
    void setResolvedId(double resolvedId);
    void setResolvedChatId(double resolvedChatId);

public slots:
    void setChatTypeEnum(tdlibQt::Enums::ChatType chatTypeEnum)
    {
        if (m_chatTypeEnum == chatTypeEnum)
            return;

        m_chatTypeEnum = chatTypeEnum;
        emit chatTypeEnumChanged(m_chatTypeEnum);
    }
    void setUsername(QString username);
    void chatReceived(const QJsonObject &chatObject);

    void setError(QString error)
    {
        if (m_error == error)
            return;

        m_error = error;
        emit errorChanged(m_error);
    }

    void setResolvedTitle(const QString &title)
    {
        if (m_resolvedTitle == title)
            return;
        m_resolvedTitle = title;
    }
protected slots:
    void errorReceived(const QJsonObject &errorObject);
};
} // namespace tdlibQt
#endif // USERNAMERESOLVER_HPP
