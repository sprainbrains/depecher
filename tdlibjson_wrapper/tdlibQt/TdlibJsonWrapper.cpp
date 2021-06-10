#include "TdlibJsonWrapper.hpp"
#include "include/AppApiInfo.hpp"
#include <iostream>
#include <QThread>
#include "ListenObject.hpp"
#include "ParseObject.hpp"
#include <td/telegram/td_log.h>
#include <MGConfItem>
#include <QStandardPaths>

namespace tdlibQt {

TdlibJsonWrapper::TdlibJsonWrapper(QObject *parent) : QObject(parent)
{
    client = td_json_client_create();
    setLogLevel(2);
}

void TdlibJsonWrapper::sendToTelegram(void *Client, const char *str)
{
#ifdef QT_DEBUG
    qDebug().noquote() << QString::fromLatin1(str);
#endif
    td_json_client_send(Client, str);
}

void TdlibJsonWrapper::sendJsonObjToTelegram(QJsonObject &queryObj, const QString &extra)
{
    if (!extra.isEmpty())
        queryObj.insert("@extra", extra);

    QJsonDocument doc(queryObj);
    QByteArray query;
#ifdef QT_DEBUG
    query = doc.toJson(QJsonDocument::Indented);
#else
    query = doc.toJson(QJsonDocument::Compact);
#endif

    sendToTelegram(client, query.constData());
}

QByteArray TdlibJsonWrapper::sendSyncroniousMessage(const QString &json)
{
    std::string reply = td_json_client_execute(client, json.toStdString().c_str());
    return QByteArray::fromStdString(reply);
}

TdlibJsonWrapper *TdlibJsonWrapper::instance()
{
    static TdlibJsonWrapper    instance;
    return &instance;
}

TdlibJsonWrapper::~TdlibJsonWrapper()
{
    td_json_client_destroy(client);
}
void TdlibJsonWrapper::startListen()
{
    listenThread = new QThread;
    parseThread = new QThread;
    //    listenSchedulerThread = new QThread;
    //    listenScheduler = new ListenScheduler();
    //    connect(listenSchedulerThread, &QThread::started,
    //            listenScheduler, &ListenScheduler::beginForever, Qt::QueuedConnection);
    //    listenScheduler->moveToThread(listenSchedulerThread);
    //    listenSchedulerThread->start();

    listenObject = new ListenObject(client);//, listenScheduler->getCondition());
    parseObject = new ParseObject();
    listenObject->moveToThread(listenThread);
    connect(listenThread, &QThread::started,
            listenObject, &ListenObject::listen, Qt::QueuedConnection);
    connect(listenThread, &QThread::destroyed,
            listenObject, &ListenObject::deleteLater, Qt::QueuedConnection);
    connect(listenObject, &ListenObject::resultReady,
            parseObject, &ParseObject::parseResponse, Qt::QueuedConnection);

    connect(parseThread, &QThread::destroyed,
            parseObject, &ParseObject::deleteLater, Qt::QueuedConnection);
    connect(parseObject, &ParseObject::updateAuthorizationState,
            this, &TdlibJsonWrapper::setAuthorizationState);
    connect(parseObject, &ParseObject::newAuthorizationState,
            this, &TdlibJsonWrapper::newAuthorizationState);

    connect(parseObject, &ParseObject::updateConnectionState,
            this, &TdlibJsonWrapper::setConnectionState);
    connect(parseObject, &ParseObject::getChat,
            this, &TdlibJsonWrapper::getChat);
    connect(parseObject, &ParseObject::callbackQueryAnswerReceived,
            this, &TdlibJsonWrapper::callbackQueryAnswerReceived);
    connect(parseObject, &ParseObject::stickerSetReceived,
            this, &TdlibJsonWrapper::stickerSetReceived);
    connect(parseObject, &ParseObject::stickerSetsReceived,
            this, &TdlibJsonWrapper::stickerSetsReceived);
    connect(parseObject, &ParseObject::stickersReceived,
            this, &TdlibJsonWrapper::stickersReceived);
    connect(parseObject, &ParseObject::updateNotificationSettingsReceived,
            this, &TdlibJsonWrapper::updateNotificationSettingsReceived);


    connect(parseObject, &ParseObject::updateChatNotificationSettingsReceived,
            this, &TdlibJsonWrapper::updateChatNotificationSettingsReceived);
    connect(parseObject, &ParseObject::updateNewChat,
            this, &TdlibJsonWrapper::updateNewChat);
    connect(parseObject, &ParseObject::updateUserReceived,
            this, &TdlibJsonWrapper::updateUserReceived);
    connect(parseObject, &ParseObject::chatReceived,
    [this](const QJsonObject & chat) {
        // TODO handle it in joinManager
        /*if (chat.contains("@extra")) {
            if (chat["@extra"].toString() == "EnSailfish") {
                auto chatPtr = ParseObject::parseChat(chat);
                QVariantMap resultType;
                switch (chatPtr->type_->get_id()) {
                case chatTypeBasicGroup::ID: {
                    resultType["type"] = QVariant::fromValue(tdlibQt::Enums::ChatType::BasicGroup);
                }
                case chatTypePrivate::ID: {
                    resultType["type"] = QVariant::fromValue(tdlibQt::Enums::ChatType::Private);
                }
                case chatTypeSecret::ID: {
                    resultType["type"] = QVariant::fromValue(tdlibQt::Enums::ChatType::Secret);
                }
                case chatTypeSupergroup::ID: {
                    chatTypeSupergroup *superGroupMetaInfo   = static_cast<chatTypeSupergroup *>
                            (chatPtr->type_.data());
                    resultType["type"] = QVariant::fromValue(tdlibQt::Enums::ChatType::Supergroup);
                    resultType["is_channel"] = superGroupMetaInfo->is_channel_;
                    resultType["supergroup_id"] = superGroupMetaInfo->supergroup_id_;
                }
                }

                emit getChatByLink(QString::fromStdString(chatPtr->title_), QString::number(chatPtr->id_),
                                   resultType, QString::number(chatPtr->last_read_inbox_message_id_),
                                   QString::number(chatPtr->last_read_outbox_message_id_),
                                   QString::number(chatPtr->last_message_->id_));
            }
        }*/
        emit chatReceived(chat);
    });
    connect(parseObject, &ParseObject::chatInviteLinkInfoReceived,
            this, &TdlibJsonWrapper::chatInviteLinkInfoReceived);
    connect(parseObject, &ParseObject::updateFile,
            this, &TdlibJsonWrapper::updateFile);
    connect(parseObject, &ParseObject::newMessages,
            this, &TdlibJsonWrapper::newMessages);
    connect(parseObject, &ParseObject::newMessageFromUpdate,
            this, &TdlibJsonWrapper::newMessageFromUpdate);
    connect(parseObject, &ParseObject::updateMessageEdited,
            this, &TdlibJsonWrapper::updateMessageEdited);
    connect(parseObject, &ParseObject::updateMessageContent,
            this, &TdlibJsonWrapper::updateMessageContent);
    connect(parseObject, &ParseObject::updateDeleteMessages,
            this, &TdlibJsonWrapper::updateDeleteMessages);
    connect(parseObject, &ParseObject::updateChatOrder,
            this, &TdlibJsonWrapper::updateChatOrder);
    connect(parseObject, &ParseObject::updateChatLastMessage,
            this, &TdlibJsonWrapper::updateChatLastMessage);
    connect(parseObject, &ParseObject::updateChatIsMarkedAsUnread,
            this, &TdlibJsonWrapper::updateChatIsMarkedAsUnread);
    connect(parseObject, &ParseObject::updateChatReadInbox,
            this, &TdlibJsonWrapper::updateChatReadInbox);
    connect(parseObject, &ParseObject::updateChatReadOutbox,
            this, &TdlibJsonWrapper::updateChatReadOutbox);
    connect(parseObject, &ParseObject::updateTotalCount,
            this, &TdlibJsonWrapper::updateTotalCount);
    connect(parseObject, &ParseObject::updateChatAction,
            this, &TdlibJsonWrapper::updateUserChatAction);
    connect(parseObject, &ParseObject::updateChatMention,
            this, &TdlibJsonWrapper::updateChatMention);
    connect(parseObject, &ParseObject::updateMentionRead,
            this, &TdlibJsonWrapper::updateMentionRead);
    connect(parseObject, &ParseObject::proxiesReceived,
            this, &TdlibJsonWrapper::proxiesReceived);
    connect(parseObject, &ParseObject::proxyReceived,
            this, &TdlibJsonWrapper::proxyReceived);
    connect(parseObject, &ParseObject::meReceived,
            this, &TdlibJsonWrapper::meReceived);
    connect(parseObject, &ParseObject::errorReceived,
    [this](const QJsonObject & errorObject) {
        if (errorObject["code"].toInt() == 420) { // FLOOD_WAIT_X
            static int floodCounter = 0;
            qDebug() << "FLOOD error: " << errorObject["message"].toString();
            ++floodCounter;
            if (floodCounter >= 5) {
                qDebug() << "Abandon the ship!";
                exit(1);
            }
        }
        emit errorReceived(errorObject);
        emit errorReceivedMap(errorObject.toVariantMap());
    });
    connect(parseObject, &ParseObject::okReceived,
            this, &TdlibJsonWrapper::okReceived);

    connect(parseObject, &ParseObject::fileReceived,
            this, &TdlibJsonWrapper::fileReceived);
    connect(parseObject, &ParseObject::messageReceived,
            this, &TdlibJsonWrapper::messageReceived);
    connect(parseObject, &ParseObject::updateMessageSendSucceeded,
            this, &TdlibJsonWrapper::updateMessageSendSucceeded);
    connect(parseObject, &ParseObject::updateSupergroup,
            this, &TdlibJsonWrapper::updateSupergroup);
    connect(parseObject, &ParseObject::secondsReceived,
            this, &TdlibJsonWrapper::secondsReceived);
    connect(parseObject, &ParseObject::textReceived,
            this, &TdlibJsonWrapper::textReceived);
    connect(parseObject, &ParseObject::updateFileGenerationStartReceived,
            this, &TdlibJsonWrapper::updateFileGenerationStartReceived);
    connect(parseObject, &ParseObject::updateFileGenerationStopReceived,
            this, &TdlibJsonWrapper::updateFileGenerationStopReceived);
    connect(parseObject, &ParseObject::usersReceived,
            this, &TdlibJsonWrapper::usersReceived);
    connect(parseObject, &ParseObject::userReceived,
            this, &TdlibJsonWrapper::userReceived);
    connect(parseObject, &ParseObject::updateUserStatusReceived,
            this, &TdlibJsonWrapper::updateUserStatusReceived);
    connect(parseObject, &ParseObject::chatsReceived,
            this, &TdlibJsonWrapper::chatsReceived);
    connect(parseObject, &ParseObject::updateNotificationGroupReceived,
            this, &TdlibJsonWrapper::updateNotificationGroupReceived);
    connect(parseObject, &ParseObject::updateActiveNotificationReceived,
            this, &TdlibJsonWrapper::updateActiveNotificationReceived);
    connect(parseObject, &ParseObject::countReceived,
            this, &TdlibJsonWrapper::countReceived);
    connect(parseObject, &ParseObject::userFullInfoReceived,
            this, &TdlibJsonWrapper::userFullInfoReceived);
    connect(parseObject, &ParseObject::supergroupFullInfoReceived,
            this, &TdlibJsonWrapper::supergroupFullInfoReceived);
    connect(parseObject, &ParseObject::basicGroupReceived,
            this, &TdlibJsonWrapper::basicGroupReceived);
    connect(parseObject, &ParseObject::basicGroupFullInfoReceived,
            this, &TdlibJsonWrapper::basicGroupFullInfoReceived);
    connect(parseObject, &ParseObject::updateBasicGroupFullInfoReceived,
            this, &TdlibJsonWrapper::updateBasicGroupFullInfoReceived);
    connect(parseObject, &ParseObject::updateBasicGroupReceived,
            this, &TdlibJsonWrapper::updateBasicGroupReceived);
    connect(parseObject, &ParseObject::supergroupMembersReceived,
            this, &TdlibJsonWrapper::supergroupMembersReceived);
    listenThread->start();
    parseThread->start();


}

bool TdlibJsonWrapper::isCredentialsEmpty() const
{
    return m_isCredentialsEmpty;
}

Enums::AuthorizationState TdlibJsonWrapper::authorizationState() const
{
    return m_authorizationState;
}

Enums::ConnectionState TdlibJsonWrapper::connectionState() const
{
    return m_connectionState;
}

int TdlibJsonWrapper::totalUnreadCount() const
{
    return m_totalUnreadCount;
}

void TdlibJsonWrapper::openChat(const QString &chat_id)
{
    QJsonObject query {
        {"@type", "openChat"},
        {"chat_id", chat_id}
    };
    sendJsonObjToTelegram(query);
}

void TdlibJsonWrapper::closeChat(const QString &chat_id)
{
    QJsonObject query {
        {"@type", "closeChat"},
        {"chat_id", chat_id}
    };
    sendJsonObjToTelegram(query);
}

void TdlibJsonWrapper::setOption(const QString &name, const QVariant &value)
{
    QString str = "{\"@type\":\"setOption\","
                  "\"name\":\"%1\","
                  "\"value\":%2}";

    QString objValue = "{\"@type\":\"%1\","
                       "\"value\":%2}";
    if (value.isNull())
        objValue = "{\"@type\":\"optionValueEmpty\"}";
    else {
        switch (value.type()) {
        case QVariant::Type::Bool:
            if (value.toBool())
                objValue = objValue.arg("optionValueBoolean", "true");
            else
                objValue = objValue.arg("optionValueBoolean", "false");
            break;
        case QVariant::Type::Int:
        case QVariant::Type::Double:
            objValue = objValue.arg("optionValueInteger", value.toString());

            break;
        case QVariant::Type::String:
            objValue = objValue.arg("optionValueString", value.toString().prepend("\"").append("\""));
            break;
        default:
            objValue = "{\"@type\":\"optionValueEmpty\"}";
            break;
        }
    }
    str = str.arg(name, objValue);

    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::getContacts()
{
    std::string getContactsStr = "{\"@type\":\"getContacts\","
                                 "\"@extra\":\"getContacts\"}";
    sendToTelegram(client, getContactsStr.c_str());
}

void TdlibJsonWrapper::getUser(const qint64 chatId, const QString &extra)
{
    QString getContactStr;
    if (extra != "") {
        getContactStr = "{\"@type\":\"getUser\","
                        "\"user_id\":\"%1\","
                        "\"@extra\":\"%2\"}";
        getContactStr = getContactStr.arg(QString::number(chatId), extra);
    } else {
        {
            getContactStr = "{\"@type\":\"getUser\","
                            "\"user_id\":\"%1\"}";
            getContactStr = getContactStr.arg(QString::number(chatId));
        }
    }
    sendToTelegram(client, getContactStr.toStdString().c_str());
}

void TdlibJsonWrapper::searchContacts(const QString &query, const int limit)
{
    QJsonObject queryObj {
        {"@type", "searchContacts"},
        {"query", query},
        {"limit", limit}
    };
    sendJsonObjToTelegram(queryObj, "searchContacts");
}

void TdlibJsonWrapper::getMe()
{
    QString getMe = "{\"@type\":\"getMe\",\"@extra\":\"getMe\"}";
    sendToTelegram(client, getMe.toStdString().c_str());
}

void TdlibJsonWrapper::requestAuthenticationPasswordRecovery()
{
    QString requestAuthenticationPasswordRecovery =
        "{\"@type\":\"requestAuthenticationPasswordRecovery\"}";
    sendToTelegram(client, requestAuthenticationPasswordRecovery.toStdString().c_str());
}

void TdlibJsonWrapper::recoverAuthenticationPassword(const QString &recoveryCode)
{
    QString recoverAuthenticationPassword =
        "{\"@type\":\"recoverAuthenticationPassword\","
        "\"recovery_code\":\"" + recoveryCode + "\","
        "\"@extra\":\"auth\"}";
    sendToTelegram(client, recoverAuthenticationPassword.toStdString().c_str());
}

void TdlibJsonWrapper::cancelDownloadFile(int fileId, bool only_if_pending)
{
    QString Pending = only_if_pending ? "true" : "false";

    QString cancelDownloadFile =
        "{\"@type\":\"cancelDownloadFile\","
        "\"file_id\":" + QString::number(fileId) + ","
        "\"only_if_pending\":" + Pending + "}";
    sendToTelegram(client, cancelDownloadFile.toStdString().c_str());
}

void TdlibJsonWrapper::cancelUploadFile(int fileId)
{
    QString cancelUploadFile =
        "{\"@type\":\"cancelUploadFile\","
        "\"file_id\":" + QString::number(fileId)  + "}";
    sendToTelegram(client, cancelUploadFile.toStdString().c_str());
}

void TdlibJsonWrapper::joinChatByInviteLink(const QString &link, const QString &extra)
{
    QJsonObject query {
        {"@type", "joinChatByInviteLink"},
        {"invite_link", link}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::joinChat(const qint64 chatId, const QString &extra)
{
    QJsonObject query {
        {"@type", "joinChat"},
        {"chat_id", QString::number(chatId)}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::leaveChat(const qint64 chatId, const QString &extra)
{
    QJsonObject query {
        {"@type", "leaveChat"},
        {"chat_id", QString::number(chatId)}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::checkChatInviteLink(const QString &link, const QString &extra)
{
    QJsonObject query {
        {"@type", "checkChatInviteLink"},
        {"invite_link", link}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getBasicGroup(const qint64 basicGroupId, const QString &extra)
{
    QJsonObject query {
        {"@type", "getBasicGroup"},
        {"basic_group_id", QString::number(basicGroupId)}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getBasicGroupFullInfo(const int groupId, const QString &extra)
{
    QJsonObject query {
        {"@type", "getBasicGroupFullInfo"},
        {"basic_group_id", groupId}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::setTotalUnreadCount(int totalUnreadCount)
{
    if (m_totalUnreadCount == totalUnreadCount)
        return;

    m_totalUnreadCount = totalUnreadCount;
    emit totalUnreadCountChanged(totalUnreadCount);
}

void TdlibJsonWrapper::changeStickerSet(const qint64 set_id, const bool is_installed, const bool is_archived)
{
    QString isInstalled = is_installed ? "true" : "false";
    QString isArchived = is_archived ? "true" : "false";

    QString changeStickerSet = "{\"@type\":\"changeStickerSet\","
                               "\"set_id\":\"" + QString::number(set_id) + "\","
                               "\"is_installed\":" + isInstalled + ","
                               "\"is_archived\":" + isArchived + "}";
    sendToTelegram(client, changeStickerSet.toStdString().c_str());
}


void TdlibJsonWrapper::getProxies()
{
    QString getProxies = "{\"@type\":\"getProxies\"}";
    sendToTelegram(client, getProxies.toStdString().c_str());
}

void TdlibJsonWrapper::addProxy(const QString &address, const int port,
                                const bool &enabled, const QVariantMap &type)
{

    QString proxyType;
    if (type["@type"] == "proxyTypeSocks5")
        proxyType = "{\"@type\":\"proxyTypeSocks5\","
                    "\"username\":\"" + type["username"].toString() + "\","
                    "\"password\":\"" + type["password"].toString() + "\""
                    "}";
    else if (type["@type"] == "proxyTypeHttp") {
        proxyType = "{\"@type\":\"proxyTypeHttp\","
                    "\"username\":\"%1\","
                    "\"password\":\"%2\","
                    "\"http_only\":%3"
                    "}";
        proxyType = proxyType.arg(type["username"].toString(), type["password"].toString(), type["http_only"].toBool() ? QString("true") : QString("false"));
    } else if (type["@type"] == "proxyTypeMtproto")
        proxyType = "{\"@type\":\"proxyTypeMtproto\","
                    "\"secret\":\"" + type["secret"].toString() + "\""
                    "}";
    QString proxy = "{\"@type\":\"addProxy\","
                    "\"server\":\"%1\","
                    "\"port\":%2,"
                    "\"enable\":%3,"
                    "\"type\":%4"
                    "}";
    proxy = proxy.arg(address, QString::number(port), enabled ? QString("true") : QString("false"), proxyType);
    sendToTelegram(client, proxy.toStdString().c_str());
}

void TdlibJsonWrapper::editProxy(const int id, const QString &address, const int port, const bool &enabled, const QVariantMap &type)
{
    QString proxyType;
    if (type["@type"] == "proxyTypeSocks5")
        proxyType = "{\"@type\":\"proxyTypeSocks5\","
                    "\"username\":\"" + type["username"].toString() + "\","
                    "\"password\":\"" + type["password"].toString() + "\""
                    "}";
    else if (type["@type"] == "proxyTypeHttp") {
        proxyType = "{\"@type\":\"proxyTypeHttp\","
                    "\"username\":\"%1\","
                    "\"password\":\"%2\","
                    "\"http_only\":%3"
                    "}";
        proxyType = proxyType.arg(type["username"].toString(), type["password"].toString(), type["http_only"].toBool() ? QString("true") : QString("false"));
    } else if (type["@type"] == "proxyTypeMtproto")
        proxyType = "{\"@type\":\"proxyTypeMtproto\","
                    "\"secret\":\"" + type["secret"].toString() + "\""
                    "}";

    QString proxy = "{\"@type\":\"editProxy\","
                    "\"server\":\"%1\","
                    "\"port\":%2,"
                    "\"enable\":%3,"
                    "\"type\":%4,"
                    "\"proxy_id\":%5"
                    "}";
    proxy = proxy.arg(address, QString::number(port), enabled ? QString("true") : QString("false"), proxyType, QString::number(id));

    sendToTelegram(client, proxy.toStdString().c_str());

}

void TdlibJsonWrapper::disableProxy()
{
    QString str = "{\"@type\":\"disableProxy\"}";
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::enableProxy(const int id)
{
    QString str = "{\"@type\":\"enableProxy\","
                  "\"proxy_id\":%1,"
                  "\"@extra\":\"%2\"}";

    str = str.arg(QString::number(id), "enableProxy_" + QString::number(id));
    sendToTelegram(client, str.toStdString().c_str());
}
void TdlibJsonWrapper::getProxyLink(const int id)
{
    QString str = "{\"@type\":\"getProxyLink\","
                  "\"proxy_id\":%1,"
                  "\"@extra\":\"%2\"}";
    str = str.arg(QString::number(id), "getProxyLink_" + QString::number(id));

    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::removeProxy(const int id)
{
    QString str = "{\"@type\":\"removeProxy\","
                  "\"proxy_id\":" + QString::number(id) + "}";
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::pingProxy(const int id)
{
    QString str = "{\"@type\":\"pingProxy\","
                  "\"proxy_id\":%1,"
                  "\"@extra\":\"%2\"}";
    str = str.arg(QString::number(id), "pingProxy_" + QString::number(id));
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::setEncryptionKey(const QString &key)
{
    std::string setDatabaseKey =
        "{\"@type\":\"setDatabaseEncryptionKey\","
        "\"new_encryption_key\":\"" + key.toStdString() + "\"}";
    sendToTelegram(client, setDatabaseKey.c_str());
    //Debug answer - Sending result for request 1: ok {}
}

void TdlibJsonWrapper::setPhoneNumber(const QString &phone)
{
    std::string setAuthenticationPhoneNumber =
        "{\"@type\":\"setAuthenticationPhoneNumber\","
        "\"phone_number\":\"" + phone.toStdString() + "\","
        "\"allow_flash_call\":false,"
        "\"is_current_phone_number\":false}";
    sendToTelegram(client, setAuthenticationPhoneNumber.c_str());

}

void TdlibJsonWrapper::checkCode(const QString &code)
{
    QJsonObject query {
        {"@type", "checkAuthenticationCode"},
        {"code", code}
    };
    sendJsonObjToTelegram(query, "checkCode");
}

void TdlibJsonWrapper::checkPassword(const QString &password)
{
    std::string setAuthenticationPassword =
        "{\"@type\":\"checkAuthenticationPassword\","
        "\"password\":\"" + password.toStdString() + "\","
        "\"@extra\":\"checkPassword\"}";

    sendToTelegram(client, setAuthenticationPassword.c_str());
}

bool TdlibJsonWrapper::migrateFilesDirectory(const QString &oldPath, const QString &newPath)
{
    qDebug() << "Trying to migrate from: " << oldPath << " to: " << newPath;
    QDir oldDir(oldPath), newDir(newPath);
    if (!oldDir.exists()) {
        qDebug() << "Nothing to migrate";
        return false;
    }
    if (!newDir.exists())
        newDir.mkpath(newPath);
    oldDir.setNameFilters({"animations", "documents", "music", "photos", "temp", "video_notes", "videos", "voice"});
    oldDir.setFilter(QDir::Dirs);
    QStringList subdirs = oldDir.entryList();
    bool partialMigration = false;
    for (const QString &subdir : subdirs) {
        qDebug() << "Trying to move: " << subdir;
        if (!QFileInfo::exists(newPath + "/" + subdir)) {
            QDir dir;
            if (!dir.rename(oldPath + "/" + subdir, newPath + "/" + subdir)) {
                qDebug() << "can't migrate: " << subdir;
                return false;
            }
        } else {
            qDebug() << (newPath + "/" + subdir) << " already exists. To avoid any overwrites, migration for that directory will not be done";
            partialMigration = true;
        }
    }

    qDebug() << "Migration finished" << (partialMigration ? " with errors" : "");

    return true;
}

void TdlibJsonWrapper::setTdlibParameters()
{
    //SEG FAULT means that json has error input variable names
    MGConfItem filesDirectory("/apps/depecher/tdlib/files_directory");
    MGConfItem useFileDatabase("/apps/depecher/tdlib/use_file_database");
    MGConfItem useChatInfoDatabase("/apps/depecher/tdlib/use_chat_info_database");
    MGConfItem useMessageDatabase("/apps/depecher/tdlib/use_message_database");
    MGConfItem enableStorageOptimizer("/apps/depecher/tdlib/enable_storage_optimizer");
    MGConfItem notificationGroupCountMax("/apps/depecher/tdlib/notification_group_count_max");
    MGConfItem notificationGroupSizeMax("/apps/depecher/tdlib/notification_group_size_max");
    setOption("notification_group_count_max", notificationGroupCountMax.value(3));
    setOption("notification_group_size_max", notificationGroupSizeMax.value(10));

    QString userDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString defaultDownloadsPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/depecher/";

    // sailjail protects user from opening random files so move depecher files directory to ~/Downloads/depecher
    if (filesDirectory.value().toString() == "") {
        MGConfItem filesDirectoryMigratedConf("/apps/depecher/tdlib/files_directory_migrated");
        if (!filesDirectoryMigratedConf.value(false).toBool())
            filesDirectoryMigratedConf.set(migrateFilesDirectory((userDir + "/.local/share/harbour-depecher"), defaultDownloadsPath));
    }

    QString filesDirectoryPath = filesDirectory.value(defaultDownloadsPath).toString();
    if (filesDirectoryPath.isEmpty())
        filesDirectoryPath = defaultDownloadsPath;

    QFileInfo checkDir(filesDirectoryPath);
    if (!checkDir.exists()) {
        QDir dir;
        dir.mkpath(filesDirectoryPath);
    }
    if (!(checkDir.isDir() && checkDir.isWritable())) {
        qDebug() << "Can not use set files_directory path: " << filesDirectoryPath;
        filesDirectoryPath = "";
    } else {
        //Disable directory from being tracked by tracker
        QFile file(filesDirectoryPath + "/.nomedia");
        if (!file.exists()) {
            file.open(QIODevice::WriteOnly);
            file.close();
        }
    }
    filesDirectory.set(filesDirectoryPath);

    QJsonObject paramsObj {
        {"database_directory", userDir + "/.local/share/harbour-depecher"},
        {"files_directory", filesDirectoryPath},
        {"api_id", tdlibQt::appid.toInt()},
        {"api_hash", tdlibQt::apphash},
        {"system_language_code", QLocale::languageToString(QLocale::system().language())},
        {"device_model", QSysInfo::prettyProductName()},
        {"system_version", QSysInfo::productVersion()},
        {"application_version", APP_VERSION},
        {"use_file_database", useFileDatabase.value(true).toBool()},
        {"use_chat_info_database", useChatInfoDatabase.value(true).toBool()},
        {"use_message_database", useMessageDatabase.value(true).toBool()},
        {"enable_storage_optimizer", enableStorageOptimizer.value(true).toBool()},
        {"use_secret_chats", false},
#ifdef TEST_DC
        {"use_test_dc", true}
#else
        {"use_test_dc", false}
#endif
    };

    QJsonObject query {
        {"@type", "setTdlibParameters"},
        {"parameters", paramsObj}
    };
    sendJsonObjToTelegram(query);
    //answer is - {"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitEncryptionKey","is_encrypted":false}}
}
void TdlibJsonWrapper::registerUser(const QString &first_name, const QString &last_name)
{
    QJsonObject query {
        {"@type", "registerUser"},
        {"first_name", first_name},
        {"last_name", last_name}
    };
    sendJsonObjToTelegram(query);
}
void TdlibJsonWrapper::getChats(const qint64 offset_chat_id, const qint64 offset_order,
                                const int limit, const QString &extra)
{
    QJsonObject query {
        {"@type", "getChats"},
        {"offset_order", QString::number(offset_order)},
        {"offset_chat_id", QString::number(offset_chat_id)},
        {"limit", limit}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getChat(const qint64 chatId, const QString &extra)
{
    QJsonObject query {
        {"@type", "getChat"},
        {"chat_id", QString::number(chatId)}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::searchChatsOnServer(const QString &query, const int limit)
{
    QString str = "{\"@type\":\"searchChatsOnServer\","
                  "\"query\":\"%1\","
                  "\"limit\":%2,"
                  "\"@extra\":\"searchChatsOnServer\""
                  "}";

    str = str.arg(query, QString::number(limit));
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::searchChats(const QString &query, const int limit)
{
    QString str = "{\"@type\":\"searchChats\","
                  "\"query\":\"%1\","
                  "\"limit\":%2,"
                  "\"@extra\":\"searchChats\""
                  "}";

    str = str.arg(query, QString::number(limit));
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::markChatUnread(const qint64 chatId, const bool flag)
{
    QString str = "{\"@type\":\"toggleChatIsMarkedAsUnread\","
                  "\"chat_id\":\"%1\","
                  "\"is_marked_as_unread\":%2}";

    str = str.arg(QString::number(chatId), flag ? "true" : "false");
    sendToTelegram(client, str.toStdString().c_str());
}

void TdlibJsonWrapper::downloadFile(int fileId, int priority, const bool sync, const QString &extra)
{
    // Limiter to avoid download loop caused by some sticker's thumbnails (tdlib 1.4)
    // https://github.com/tdlib/td/issues/778
    int downloadCnt = downloadMap.value(fileId, 0) + 1;
    if (downloadCnt == 2) {
        QTimer::singleShot(4000, [this, fileId] () {
            if (downloadMap.value(fileId, 0) == 2) {
#ifdef QT_DEBUG
                qDebug() << "no change, clear download counter";
#endif
                downloadMap.remove(fileId);
            }
        });
    } else if (downloadCnt >= 3) {
        if (downloadCnt == 3)
            downloadMap[fileId] = downloadCnt;
#ifdef QT_DEBUG
        qDebug() << "blacklisted, return: " << fileId;
#endif
        return;
    }

    downloadMap[fileId] = downloadCnt;

    priority = qBound(1, priority, 32);

    QJsonObject query {
        {"@type", "downloadFile"},
        {"file_id", fileId},
        {"priority", priority},
        {"offset", 0},
        {"limit", 0},
        {"synchronous", sync}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getChatHistory(qint64 chat_id, qint64 from_message_id,
                                      int offset,
                                      int limit, bool only_local, const QString &extra)
{
    QJsonObject query {
        {"@type", "getChatHistory"},
        {"chat_id", QString::number(chat_id)},
        {"from_message_id", QString::number(from_message_id)},
        {"offset", offset},
        {"limit", limit},
        {"only_local", only_local}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::searchChatMessages(const qint64 chat_id, const qint64 from_message_id, const QString &query,
        const int sender_user_id, const int offset, const int limit,
        const Enums::SearchFilter &filter, const QString &extra)
{
    QJsonObject queryObj {
        {"@type", "searchChatMessages"},
        {"chat_id", QString::number(chat_id)},
        {"from_message_id", QString::number(from_message_id)},
        {"query", query},
        {"sender_user_id", sender_user_id},
        {"offset", offset},
        {"limit", limit},
        {"filter", QJsonObject {
                {"@type", m_searchFilters[(int)filter - 5]}
            }}
    };
    sendJsonObjToTelegram(queryObj, extra);
}

void TdlibJsonWrapper::createPrivateChat(const int user_id, bool force, const QString &extra)
{
    QJsonObject query {
        {"@type", "createPrivateChat"},
        {"user_id", user_id},
        {"force", force}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::deleteChatHistory(qint64 chat_id, bool remove_from_chat_list, bool revoke, const QString &extra)
{
    QJsonObject query {
        {"@type", "deleteChatHistory"},
        {"chat_id", QString::number(chat_id)},
        {"remove_from_chat_list", remove_from_chat_list},
        {"revoke", revoke}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getSupergroupMembers(const int supergroup_id, const QString &search,
                                            const int offset, const int limit, const QString &extra)
{
    QJsonObject filter;
    if (search.isEmpty()) {
        filter = QJsonObject {
            {"@type", "supergroupMembersFilterRecent"}
        };
    } else {
        filter = QJsonObject {
            {"@type", "supergroupMembersFilterSearch"},
            {"query", search}
        };
    }

    QJsonObject query {
        {"@type", "getSupergroupMembers"},
        {"supergroup_id", supergroup_id},
        {"filter", filter},
        {"offset", offset},
        {"limit", limit}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getChatMessageCount(qint64 chat_id, Enums::SearchFilter filter, bool return_local, const QString &extra)
{
    QJsonObject query {
        {"@type", "getChatMessageCount"},
        {"chat_id", QString::number(chat_id)},
        {"return_local", return_local},
        {"filter", QJsonObject {
                {"@type", m_searchFilters[(int)filter - 5]}
            }}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getUserFullInfo(const int user_id, const QString &extra)
{
    QJsonObject query {
        {"@type", "getUserFullInfo"},
        {"user_id", user_id}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getSupergroupFullInfo(const int supergroup_id, const QString &extra)
{
    QJsonObject query {
        {"@type", "getSupergroupFullInfo"},
        {"supergroup_id", supergroup_id}
    };
    sendJsonObjToTelegram(query, extra);
}
void TdlibJsonWrapper::searchPublicChat(const QString &username, const QString &extra)
{
    QJsonObject query {
        {"@type", "searchPublicChat"},
        {"username", username}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::searchPublicChats(const QString &query, const QString &extra)
{
    QJsonObject queryObj {
        {"@type", "searchPublicChats"},
        {"query", query}
    };
    sendJsonObjToTelegram(queryObj, extra);
}

void TdlibJsonWrapper::getAttachedStickerSets(const int file_id)
{
    QJsonObject query {
        {"@type", "getAttachedStickerSets"},
        {"file_id", file_id}
    };
    sendJsonObjToTelegram(query, "getAttachedStickerSets");
}
void TdlibJsonWrapper::getStickerSet(const qint64 set_id)
{
    QJsonObject query {
        {"@type", "getStickerSet"},
        {"set_id", QString::number(set_id)}
    };
    sendJsonObjToTelegram(query);
}
void TdlibJsonWrapper::getInstalledStickerSets(const bool is_masks)
{
    QJsonObject query {
        {"@type", "getInstalledStickerSets"},
        {"is_masks", is_masks}
    };
    sendJsonObjToTelegram(query, "getInstalledStickerSets");
}
void TdlibJsonWrapper::getTrendingStickerSets()
{
    QString getTrendingStickerSetsStr = QString("{\"@type\":\"getTrendingStickerSets\","
                                        "\"@extra\": \"getTrendingStickerSets\"}");
    sendToTelegram(client, getTrendingStickerSetsStr.toStdString().c_str());
}
void TdlibJsonWrapper::getFavoriteStickers()
{
    QString getFavoriteStickersStr = "{\"@type\":\"getFavoriteStickers\""
                                     ",\"@extra\": \"getFavoriteStickers\"}";
    sendToTelegram(client, getFavoriteStickersStr.toStdString().c_str());
}
void TdlibJsonWrapper::getRecentStickers(const bool is_attached)
{
    QJsonObject query {
        {"@type", "getRecentStickers"},
        {"is_attached", is_attached}
    };
    sendJsonObjToTelegram(query, "getRecentStickers");
}

void TdlibJsonWrapper::logOut()
{
    std::string logOut = "{\"@type\":\"logOut\"}";
    sendToTelegram(client, logOut.c_str());
}

void TdlibJsonWrapper::sendMessage(const QString &json)
{
    QString jsonStr = json;
    //Bug in TDLib
    while (jsonStr.at(jsonStr.length() - 1) == '\n')
        jsonStr = jsonStr.remove(jsonStr.length() - 1, 1);
    sendToTelegram(client, jsonStr.toStdString().c_str());
}

void TdlibJsonWrapper::forwardMessage(const qint64 chat_id, const qint64 from_chat_id, const QVector<qint64> message_ids, const bool disable_notification, const bool from_background, const bool as_album)
{
    QString ids = "";
    for (auto id : message_ids)
        ids.append(QString::number(id) + ",");

    ids = ids.remove(ids.length() - 1, 1);

    QString forwardMessagesStr = "{\"@type\":\"forwardMessages\","
                                 "\"chat_id\":\"%1\","
                                 "\"from_chat_id\":\"%2\","
                                 "\"message_ids\":[%3],"
                                 "\"disable_notification\":%4,"
                                 "\"from_background\":%5,"
                                 "\"as_album\":%6,"
                                 "\"@extra\":\"forwardMessagesExtra\"}";
    forwardMessagesStr = forwardMessagesStr.arg(QString::number(chat_id),
                         QString::number(from_chat_id),
                         ids,
                         disable_notification ? QString("true") : QString("false"),
                         from_background ? QString("true") : QString("false"),
                         as_album ? QString("true") : QString("false"));

    sendToTelegram(client, forwardMessagesStr.toStdString().c_str());
}

void TdlibJsonWrapper::getMessage(const qint64 chat_id, const qint64 message_id, const QString &extra)
{
    QJsonObject query {
        {"@type", "getMessage"},
        {"chat_id", QString::number(chat_id)},
        {"message_id", QString::number(message_id)}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::getMessages(const qint64 chat_id, QVector<qint64> message_ids, const QString &extra)
{
    QJsonArray messagesIds;
    for (int i = 0; i < message_ids.size(); i++)
        messagesIds.append(QString::number(message_ids[i]));

    QJsonObject query {
        {"@type", "getMessages"},
        {"chat_id", QString::number(chat_id)},
        {"message_ids", messagesIds}
    };
    sendJsonObjToTelegram(query, extra);
}

void TdlibJsonWrapper::viewMessages(const QString &chat_id, const QVariantList &messageIds,
                                    const bool force_read)
{
    QJsonObject query {
        {"@type", "viewMessages"},
        {"chat_id", chat_id},
        {"force_read", force_read},
        {"message_ids", QJsonArray::fromVariantList(messageIds)}
    };

    sendJsonObjToTelegram(query);
}

void TdlibJsonWrapper::deleteMessages(const qint64 chat_id, const QVector<qint64> message_ids,
                                      const bool revoke)
{
    QJsonArray ids;
    for (auto id : message_ids)
        ids.append(QString::number(id));

    QJsonObject query {
        {"@type", "deleteMessages"},
        {"chat_id", QString::number(chat_id)},
        {"revoke", revoke},
        {"message_ids", ids}
    };
    sendJsonObjToTelegram(query);
}

void TdlibJsonWrapper::setChatMemberStatus(const qint64 chat_id, const int user_id,
        const QString &status)
{
    QString setChatMemberStatusStr = "{\"@type\":\"deleteMessages\","
                                     "\"chat_id\":\"" + QString::number(chat_id) + "\","
                                     "\"user_id\":" + QString::number(user_id) + ","
                                     "\"status\":\"" + status + "\"}";
    sendToTelegram(client, setChatMemberStatusStr.toStdString().c_str());
}

void TdlibJsonWrapper::setIsCredentialsEmpty(bool isCredentialsEmpty)
{
    if (m_isCredentialsEmpty == isCredentialsEmpty)
        return;

    m_isCredentialsEmpty = isCredentialsEmpty;
    emit isCredentialsEmptyChanged(isCredentialsEmpty);
}

void TdlibJsonWrapper::setAuthorizationState(Enums::AuthorizationState &authorizationState)
{
    if (authorizationState == tdlibQt::Enums::AuthorizationState::AuthorizationStateWaitTdlibParameters)
        setTdlibParameters();
    else if (authorizationState == tdlibQt::Enums::AuthorizationState::AuthorizationStateWaitEncryptionKey)
        setEncryptionKey();
    if (m_authorizationState == authorizationState)
        return;

    m_authorizationState = authorizationState;
    emit authorizationStateChanged(authorizationState);
}

void TdlibJsonWrapper::setConnectionState(Enums::ConnectionState &connState)
{
    auto connectionState = connState;

    if (m_connectionState == connectionState)
        return;

    m_connectionState = connectionState;
    emit connectionStateChanged(connectionState);
}

void TdlibJsonWrapper::close()
{
    QJsonObject query {
        {"@type", "close"}
    };
    sendJsonObjToTelegram(query);
}

void TdlibJsonWrapper::setLogLevel(int new_verbosity_level)
{
    QJsonObject query {
        {"@type", "setLogVerbosityLevel"},
        {"new_verbosity_level", new_verbosity_level}
    };
    QJsonDocument doc(query);
    sendSyncroniousMessage(doc.toJson());
}

void TdlibJsonWrapper::changeNotificationSettings(const qint64 &chatId, bool mute)
{
    setChatNotificationSettings muteFunction;
    muteFunction.chat_id_ = chatId;
    if (mute)
        muteFunction.notification_settings_ = QSharedPointer<chatNotificationSettings>(new chatNotificationSettings(false, std::numeric_limits<int>::max(), true, std::string(""), true, false, true, false, false, false));
    else
        muteFunction.notification_settings_ = QSharedPointer<chatNotificationSettings>(new chatNotificationSettings(false, 0, true, std::string(""), true, false, true, false, false, false));

    TlStorerToString jsonConverter;
    muteFunction.store(jsonConverter, "muteFunction");
    QString jsonString = QJsonDocument::fromVariant(jsonConverter.doc["muteFunction"]).toJson();
    jsonString = jsonString.replace("\"null\"", "null");
    sendMessage(jsonString);
}

}// namespace tdlibQt
