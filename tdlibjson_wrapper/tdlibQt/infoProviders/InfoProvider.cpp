#include "InfoProvider.hpp"
#include "tdlibQt/TdlibJsonWrapper.hpp"
#include "tdlibQt/models/singletons/UsersModel.hpp"
#include "tdlibQt/ParseObject.hpp"
#include "tdlibQt/include/TdlibNamespace.hpp"
#include <QMetaEnum>
namespace tdlibQt {
static const QString c_extra = QLatin1String("InfoProvider %1");

InfoProvider::InfoProvider(QObject *parent) : QObject(parent)
{
    m_tdlibJson = TdlibJsonWrapper::instance();
    connect(m_tdlibJson, &TdlibJsonWrapper::countReceived,
            this, &InfoProvider::countReceived);
    connect(m_tdlibJson, &TdlibJsonWrapper::fileReceived,
            this, &InfoProvider::processFile);
    connect(m_tdlibJson, &TdlibJsonWrapper::updateChatNotificationSettingsReceived,
            this, &InfoProvider::updateChatNotificationSettings);
}
void InfoProvider::processFile(const QJsonObject &fileObject)
{
    if (fileObject["@extra"].toString() == c_extra.arg(QString::number(m_chatId))) {
        auto file = ParseObject::parseFile(fileObject);
        if (file->local_->is_downloading_completed_) {
            m_chat->photo_->small_ = file;
            emit avatarChanged();
        }
    }
}
QString InfoProvider::avatar() const
{
    if (m_chat.data()) {
        if (m_chat->photo_.data()) {
            if (m_chat->photo_->small_.data()) {
                if (m_chat->photo_->small_->local_->is_downloading_completed_)
                    return QString::fromStdString(m_chat->photo_->small_->local_->path_);
                else
                    m_tdlibJson->downloadFile(m_chat->photo_->small_->id_, 20, false, c_extra.arg(QString::number(m_chatId)));
            }
        }
    }
    return QString();
}

void InfoProvider::countReceived(const QJsonObject &countObject)
{
    if (countObject.keys().contains("@extra")) {
        QString filter = countObject["@extra"].toString();
        Enums::SearchFilter searchFilter = (Enums::SearchFilter)
                                           QMetaEnum::fromType<tdlibQt::Enums::SearchFilter>().keyToValue(filter.toStdString().c_str());
        switch (searchFilter) {
        case Enums::SearchFilter::Photo:
            setPhotoCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::Video:
            setVideoCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::Document:
            setFileCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::Audio:
            setAudioCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::Url:
            setLinkCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::VoiceNote:
            setVoiceCount(countObject["count"].toInt());
            break;
        case Enums::SearchFilter::Animation:
            setAnimationCount(countObject["count"].toInt());
            break;
        default:
            break;
        }
    }
}

void InfoProvider::updateChatNotificationSettings(const QJsonObject &updateChatNotificationSettingsObject)
{
    qint64 chat_id = ParseObject::getInt64(updateChatNotificationSettingsObject["chat_id"]);
    if (chat_id == m_chatId)
        emit muteForChanged();
}


void InfoProvider::setChatId(double chatId)
{
    qWarning("Floating point comparison needs context sanity check");
    if (qFuzzyCompare(m_chatId, chatId))
        return;
    m_chatId = chatId;
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Photo,
                                     false, "Photo");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Video,
                                     false, "Video");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Document,
                                     false, "Document");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Audio,
                                     false, "Audio");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Url,
                                     false, "Url");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::VoiceNote,
                                     false, "VoiceNote");
    m_tdlibJson->getChatMessageCount(m_chatId, Enums::SearchFilter::Animation,
                                     false, "Animation");
    m_chat = UsersModel::instance()->getChat(m_chatId);
    emit chatIdChanged(m_chatId);
    emit muteForChanged();
}
int InfoProvider::muteFor() const
{
    if (m_chatId != -1)
        return UsersModel::instance()->getChatMuteFor(m_chatId);
    return 0;
}
void InfoProvider::changeNotifications(bool mute)
{
    if (m_chatId != -1) {
        qint64 chat_id = (qint64)m_chatId;
        m_tdlibJson->changeNotificationSettings(chat_id, mute);
    }
}
void InfoProvider::joinChat()
{
    m_tdlibJson->joinChat((qint64)chatId(), c_extra.arg(QString::number(m_chatId)));
}

void InfoProvider::leaveChat()
{
    m_tdlibJson->leaveChat((qint64)chatId(), c_extra.arg(QString::number(m_chatId)));
}
} //namespace tdlibQt
