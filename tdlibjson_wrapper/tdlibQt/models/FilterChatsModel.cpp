#include "FilterChatsModel.hpp"

namespace tdlibQt {
FilterChatsModel::FilterChatsModel(QObject *parent):
    QSortFilterProxyModel(parent)
{
}

QString FilterChatsModel::search() const
{
    return m_search;
}

void FilterChatsModel::setSearch(const QString &search)
{
    if (m_search == search || !sourceModel())
        return;
    m_search = search;
    invalidateFilter();
    emit searchChanged();
}

bool FilterChatsModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);

    static const int titleRole = sourceModel()->roleNames().key("title");

    if (m_search.isEmpty())
        return true;

    return sourceModel()->data(index, titleRole).toString().contains(m_search, Qt::CaseInsensitive);
}

int FilterChatsModel::sourceIndex(const int idx)
{
    return mapToSource(index(idx, 0)).row();
}

} // tdlibQt
