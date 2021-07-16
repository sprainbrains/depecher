#ifndef FILEWORKER_HPP
#define FILEWORKER_HPP

#include <QObject>

class FileWorker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString picturesPath READ picturesPath CONSTANT)
public:
    explicit FileWorker(QObject *parent = 0);

    QString picturesPath() const;

private:
    QString m_picturesPath;

public slots:
    bool savePictureToGallery(const QString &sourcePath);
    QString openContact(const QString &firstName, const QString &lastName, const QString &phoneNumber, const int userId);
};

#endif // FILEWORKER_HPP
