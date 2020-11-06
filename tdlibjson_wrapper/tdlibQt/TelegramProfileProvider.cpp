#include "TelegramProfileProvider.hpp"
#include <QDebug>
#include <QImageReader>
namespace tdlibQt {
TelegramProfileProvider::TelegramProfileProvider() : QQuickImageProvider(
        QQuickImageProvider::Image)
{

}

QImage TelegramProfileProvider::requestImage(const QString &id, QSize *size,
        const QSize &requestedSize)
{
    QImage result;
    if (id == "undefined")
        return result;

    //https://github.com/tdlib/td/issues/264
    if (id.right(9) == ".jpg.webp") {
        QImageReader imgReader(id.left(id.length() - 1 - 4), "webp");
        result = imgReader.read();
        if (imgReader.error() == QImageReader::InvalidDataError || imgReader.error() == QImageReader::DeviceError) {
            imgReader.setFormat("jpg");
            result = imgReader.read();
        }
    } else {
        QImageReader imgReader(id);
        result = imgReader.read();
    }

    // TODO: Add option for fast transformation
    if (!requestedSize.isEmpty())
        result = result.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    *size = result.size();
    return result;
}

} //namespace tdlibQt
