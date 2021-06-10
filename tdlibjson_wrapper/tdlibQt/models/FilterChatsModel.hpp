#ifndef FILTERCHATSMODEL_HPP
#define FILTERCHATSMODEL_HPP

#include <QSortFilterProxyModel>
namespace tdlibQt {
class FilterChatsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString search READ search WRITE setSearch NOTIFY searchChanged)
public:
    FilterChatsModel(QObject *parent = 0);

    QString search() const;
    void setSearch(const QString &search);

    Q_INVOKABLE int sourceIndex(const int idx);


private:
    QString m_search;

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const;

signals:
    void searchChanged();
};
} // tdlibQt

#endif // FILTERCHATSMODEL_HPP
