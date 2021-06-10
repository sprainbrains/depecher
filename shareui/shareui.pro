TEMPLATE = lib


TARGET = $$qtLibraryTarget(depechershareplugin)

contains(QT_ARCH, arm64) {
    target.path = /usr/lib64/nemo-transferengine/plugins
} else {
    target.path = /usr/lib/nemo-transferengine/plugins
}

QT += dbus
CONFIG += plugin link_pkgconfig
PKGCONFIG += nemotransferengine-qt5

INSTALLS += target

HEADERS += \
    DepecherPluginInfo.hpp \
    DepecherMediaTransfer.hpp \
    DepecherTransferIface.hpp

SOURCES += \
    DepecherPluginInfo.cpp \
    DepecherMediaTransfer.cpp \
    DepecherTransferIface.cpp

DISTFILES +=
